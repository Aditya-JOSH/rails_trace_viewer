module RailsTraceViewer
  module Subscribers
    class ViewSubscriber
      EVENTS = ["render_template.action_view", "render_partial.action_view"]

      def self.attach
        return if @attached
        @attached = true

        EVENTS.each do |event|
          ActiveSupport::Notifications.subscribe(event) do |*_args, payload|
            next unless RailsTraceViewer::TraceContext.active?

            file = payload[:identifier]
            next unless file && file.include?(Rails.root.join("app").to_s)

            node = {
              id: SecureRandom.uuid,
              parent_id: RailsTraceViewer::TraceContext.parent_id,
              type: "view",
              name: file.split("/app/").last,
              source: file.sub(Rails.root.to_s, ''),
              layout: payload[:layout],
              full_path: file,
              children: []
            }

            RailsTraceViewer::Collector.add_node(RailsTraceViewer::TraceContext.trace_id, node)
          end
        end
      end
    end
  end
end
