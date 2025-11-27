module RailsTraceViewer
  class TraceContext
    THREAD_KEY = :rails_trace_viewer_context

    class << self
      def context
        Thread.current[THREAD_KEY] ||= {
          active: false,
          trace_id: nil,
          stack: []
        }
      end

      def start!(trace_id)
        ctx = context
        ctx[:active] = true
        ctx[:trace_id] = trace_id
        ctx[:stack] = []
      end

      def start_job!(trace_id)
        ctx = context
        ctx[:active] = true
        ctx[:trace_id] = trace_id
        ctx[:stack] ||= []
      end
      
      def stop!
        ctx = context
        ctx[:active] = false
        ctx[:trace_id] = nil
        ctx[:stack] = []
      end

      def active?
        context[:active]
      end

      def trace_id
        context[:trace_id]
      end

      def parent_id
        context[:stack].last
      end

      def push(node_id)
        context[:stack] << node_id
      end

      def pop
        context[:stack].pop
      end
    end
  end
end
