module RailsTraceViewer
  module Subscribers
    class SqlSubscriber
      def self.attach
        return if @attached
        @attached = true

        ActiveSupport::Notifications.subscribe("sql.active_record") do |*_args, payload|
          next unless RailsTraceViewer::TraceContext.active?
          next if payload[:name] == "SCHEMA"

          source = extract_app_source(caller)
          next unless source

          raw_binds = payload[:type_casted_binds]
          if raw_binds.respond_to?(:call)
            raw_binds = raw_binds.call
          end

          binds = (raw_binds || []).map { |val| val.to_s }

          node = {
            id: SecureRandom.uuid,
            parent_id: RailsTraceViewer::TraceContext.parent_id,
            type: "sql",
            name: payload[:sql],
            source: source,
            full_sql: payload[:sql],
            bind_values: binds,
            connection_id: payload[:connection_id],
            children: []
          }

          RailsTraceViewer::Collector.add_node(RailsTraceViewer::TraceContext.trace_id, node)
        end
      end

      def self.extract_app_source(bt)
        bt.find { |line| line.include?("/app/") }
      end
    end
  end
end
