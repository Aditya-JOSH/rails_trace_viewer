require "concurrent/map"

module RailsTraceViewer
  class JobLinkRegistry
    @store   = Concurrent::Map.new
    @pending = Concurrent::Map.new

    class << self
      def register(job, trace_id:, enqueue_node_id:)
        job_id = job.job_id

        @store[job_id] = {
          trace_id: trace_id,
          enqueue_node_id: enqueue_node_id
        }

        if @pending[job_id]
          @pending[job_id].each do |callback|
            callback.call(trace_id, enqueue_node_id)
          end
          @pending.delete(job_id)
        end
      end

      def on_perform(job, &block)
        job_id = job.job_id

        if @store[job_id]
          data = @store[job_id]
          block.call(data[:trace_id], data[:enqueue_node_id])
        else
          @pending[job_id] ||= []
          @pending[job_id] << block
        end
      end

      def delete(job)
        @store.delete(job.job_id)
      end
    end
  end
end
