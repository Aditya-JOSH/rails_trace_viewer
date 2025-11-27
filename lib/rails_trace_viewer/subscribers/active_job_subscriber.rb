module RailsTraceViewer
  module Subscribers
    class ActiveJobSubscriber
      def self.attach
        return if @attached
        @attached = true

        safe_serialize = ->(data) { JSON.parse(data.to_json) rescue data.to_s }

        ActiveSupport::Notifications.subscribe("enqueue.active_job") do |*_args, payload|
          job = payload[:job]
          next if job.class.include?(Sidekiq::Worker)

          if RailsTraceViewer::TraceContext.active?
            trace_id  = RailsTraceViewer::TraceContext.trace_id
            parent_id = RailsTraceViewer::TraceContext.parent_id
          else
            trace_id  = SecureRandom.uuid
            parent_id = nil
            RailsTraceViewer::TraceContext.start!(trace_id)
            RailsTraceViewer::Collector.start_trace(trace_id)
          end

          enqueue_node_id = SecureRandom.uuid

          node = {
            id: enqueue_node_id,
            parent_id: parent_id,
            type: "job_enqueue",
            name: job.class.name,
            source: "ActiveJob Enqueue",
            queue: job.queue_name,
            job_id: job.job_id,
            arguments: safe_serialize.call(job.arguments),
            scheduled_at: job.scheduled_at,
            priority: job.priority,
            children: []
          }

          RailsTraceViewer::JobLinkRegistry.register(job, trace_id: trace_id, enqueue_node_id: enqueue_node_id)
          RailsTraceViewer::Collector.add_node(trace_id, node)
        end

        ActiveSupport::Notifications.subscribe("perform_start.active_job") do |*_args, payload|
          job = payload[:job]

          RailsTraceViewer::JobLinkRegistry.on_perform(job) do |trace_id, enqueue_node_id|
            RailsTraceViewer::TraceContext.start_job!(trace_id)
            RailsTraceViewer::Collector.start_trace(trace_id)

            node_id = SecureRandom.uuid
            node = {
              id: node_id,
              parent_id: enqueue_node_id,
              type: "job_perform",
              name: job.class.name,
              source: "ActiveJob Perform",
              job_id: job.job_id,
              arguments: safe_serialize.call(job.arguments),
              executions: job.executions,
              children: []
            }

            RailsTraceViewer::Collector.add_node(trace_id, node)
            RailsTraceViewer::TraceContext.push(node_id)
            RailsTraceViewer::JobLinkRegistry.delete(job)
          end
        end
      end
    end
  end
end
