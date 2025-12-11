module RailsTraceViewer
  module Subscribers
    class SidekiqSubscriber
      def self.attach
        return unless defined?(Sidekiq)
        return if @attached
        @attached = true

        Sidekiq.configure_server do |config|
          config.server_middleware { |chain| chain.add ServerMiddleware }
          config.client_middleware { |chain| chain.add ClientMiddleware }
        end
        Sidekiq.configure_client do |config|
          config.client_middleware { |chain| chain.add ClientMiddleware }
        end
      end

      module SafeSerializer
        def self.serialize(args)
          return args unless args.is_a?(Array) || args.is_a?(Hash)
          JSON.parse(args.to_json) rescue ["(Unserializable)"]
        end
      end

      class ClientMiddleware
        def call(worker_class, job, queue, redis_pool)

          if RailsTraceViewer::TraceContext.active?
            trace_id  = RailsTraceViewer::TraceContext.trace_id
            parent_id = RailsTraceViewer::TraceContext.parent_id
          else
            trace_id = SecureRandom.uuid
            parent_id = nil
          end

          enqueue_node_id = SecureRandom.uuid
          job["_trace_id"] = trace_id
          job["_enqueue_node_id"] = enqueue_node_id

          safe_args = SafeSerializer.serialize(job["args"])

          node = {
            id: enqueue_node_id,
            parent_id: parent_id,
            type: "job_enqueue",
            name: "#{worker_class} (Enqueue)",
            source: "Sidekiq Client",
            worker_class: worker_class.to_s,
            queue: queue,
            job_arguments: safe_args,
            jid: job["jid"],
            children: []
          }

          RailsTraceViewer::Collector.add_node(trace_id, node)
          
          yield
        end
      end

      class ServerMiddleware
        def call(worker, job, queue)
          trace_id = job["_trace_id"]
          parent_id = job["_enqueue_node_id"]
          perform_node_id = nil

          if trace_id
            RailsTraceViewer::TraceContext.start_job!(trace_id)
            RailsTraceViewer::Collector.start_trace(trace_id)

            perform_node_id = SecureRandom.uuid
            safe_args = SafeSerializer.serialize(job["args"])

            node = {
              id: perform_node_id,
              parent_id: parent_id, 
              type: "job_perform",
              name: "#{worker.class} (Perform)",
              source: "Sidekiq Server",
              worker_class: worker.class.to_s,
              queue: queue,
              job_arguments: safe_args,
              jid: job["jid"],
              retry_count: job["retry_count"],
              children: []
            }

            RailsTraceViewer::Collector.add_node(trace_id, node)
            RailsTraceViewer::TraceContext.push(perform_node_id)
          end

          yield
        ensure
          if trace_id
            RailsTraceViewer::TraceContext.pop if perform_node_id
            RailsTraceViewer::TraceContext.stop!
          end
        end
      end
    end
  end
end
