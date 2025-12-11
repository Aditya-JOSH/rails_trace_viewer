module RailsTraceViewer
  module Subscribers
    class SqlSubscriber
      
      IGNORED_SQL_PATTERNS = /\A(?:BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE SAVEPOINT)\b/i
      IGNORED_PAYLOAD_NAMES = ["SCHEMA"].to_set

      def self.attach
        return if @attached
        @attached = true

        ActiveSupport::Notifications.subscribe("sql.active_record") do |*_args, payload|
          next unless RailsTraceViewer::TraceContext.active?
          next if IGNORED_PAYLOAD_NAMES.include?(payload[:name])

          sql = (payload[:sql] || "").to_s
          next if sql.match?(IGNORED_SQL_PATTERNS)

          source = extract_app_source(caller)
          next unless source

          raw_binds = payload[:type_casted_binds]
          raw_binds = raw_binds.call if raw_binds.respond_to?(:call)
          binds = (raw_binds || []).map { |val| val.to_s }

          node = {
            id: SecureRandom.uuid,
            parent_id: RailsTraceViewer::TraceContext.parent_id,
            type: "sql",
            name: sql,
            source: source,
            full_sql: sql,
            bind_values: binds,
            connection_id: payload[:connection_id],
            children: []
          }

          RailsTraceViewer::Collector.add_node(RailsTraceViewer::TraceContext.trace_id, node)
        end
      end

      def self.extract_app_source(bt)
        app_root = Rails.root.to_s
        bt.find { |line|
          path = line.to_s
          next false unless path.start_with?(app_root)
          next false if path.include?("/vendor/") || path.include?("/node_modules/")
          next false if path.include?("/rails_trace_viewer/")
          true
        }
      end
    end
  end
end
