module RailsTraceViewer
  module Subscribers
    class ControllerSubscriber
      def self.attach
        return if @attached
        @attached = true
        
        ActiveSupport::Notifications.subscribe("start_processing.action_controller") do |*, payload|
          controller_name = payload[:controller].to_s
          next if controller_name.start_with?("RailsTraceViewer::")

          trace_id = SecureRandom.uuid
          RailsTraceViewer::TraceContext.start!(trace_id)
          RailsTraceViewer::Collector.start_trace(trace_id)

          safe_params = payload[:params].to_unsafe_h rescue payload[:params]
          safe_params = safe_params.except("controller", "action") 

          route = RailsTraceViewer::RouteResolver.resolve(payload[:path], payload[:method])
          route_node_id = SecureRandom.uuid

          route_node = {
            id: route_node_id,
            parent_id: nil,
            type: "route",
            name: "#{route[:verb]} #{route[:path]}",
            source: payload[:path],
            verb: route[:verb],
            url_pattern: route[:path],
            route_name: route[:name],
            children: []
          }
          RailsTraceViewer::Collector.add_node(trace_id, route_node)

          request_node = {
            id: trace_id,
            parent_id: route_node_id,
            type: "request",
            name: "#{payload[:controller]}##{payload[:action]}",
            source: "#{payload[:controller]}.rb",
            format: payload[:format],
            params: safe_params,
            children: []
          }
          RailsTraceViewer::Collector.add_node(trace_id, request_node)
          RailsTraceViewer::TraceContext.push(trace_id)
        end
      end
    end
  end
end
