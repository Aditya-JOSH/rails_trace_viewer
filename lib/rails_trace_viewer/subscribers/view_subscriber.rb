module RailsTraceViewer
  module Subscribers
    class ViewSubscriber
      def self.attach
        return if @attached
        @attached = true

        subscriber = new
        ActiveSupport::Notifications.subscribe("render_template.action_view", subscriber)
        ActiveSupport::Notifications.subscribe("render_partial.action_view", subscriber)
      end

      def start(name, id, payload)
        file = payload[:identifier]
        
        return unless file && file.start_with?(Rails.root.to_s)

        if !RailsTraceViewer::TraceContext.active?
          trace_id = SecureRandom.uuid
          RailsTraceViewer::TraceContext.start!(trace_id)
          RailsTraceViewer::Collector.start_trace(trace_id)
          Thread.current["rtv_view_root_#{id}"] = true
        end

        trace_id = RailsTraceViewer::TraceContext.trace_id
        parent_id = RailsTraceViewer::TraceContext.parent_id
        node_id = SecureRandom.uuid

        Thread.current["rtv_view_node_#{id}"] = node_id

        relative_path = file.sub(Rails.root.to_s, '')

        node = {
          id: node_id,
          parent_id: parent_id,
          type: "view",
          name: relative_path.split("/").last,
          source: relative_path,
          layout: payload[:layout],
          full_path: file,
          children: []
        }

        RailsTraceViewer::Collector.add_node(trace_id, node)
        RailsTraceViewer::TraceContext.push(node_id)
      end

      def finish(name, id, payload)
        if Thread.current["rtv_view_node_#{id}"]
          RailsTraceViewer::TraceContext.pop
          Thread.current["rtv_view_node_#{id}"] = nil
        end

        if Thread.current["rtv_view_root_#{id}"]
          RailsTraceViewer::TraceContext.stop!
          Thread.current["rtv_view_root_#{id}"] = nil
        end
      end
    end
  end
end
