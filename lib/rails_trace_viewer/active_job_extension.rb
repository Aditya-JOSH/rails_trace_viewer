module RailsTraceViewer
  module ActiveJobExtension
    extend ActiveSupport::Concern

    included do
      attr_accessor :rtv_trace_id, :rtv_parent_id

      around_enqueue do |job, block|
        if defined?(RailsTraceViewer) && RailsTraceViewer.enabled
          if RailsTraceViewer::TraceContext.active?
            job.rtv_trace_id  = RailsTraceViewer::TraceContext.trace_id
            job.rtv_parent_id = RailsTraceViewer::TraceContext.parent_id
          else
            job.rtv_trace_id  ||= SecureRandom.uuid
            job.rtv_parent_id ||= nil
          end
        end

        block.call
      end
    end

    def serialize
      data = super
      
      if defined?(RailsTraceViewer) && RailsTraceViewer.enabled
        data["rtv_trace_id"]  = rtv_trace_id  if respond_to?(:rtv_trace_id)  && rtv_trace_id
        data["rtv_parent_id"] = rtv_parent_id if respond_to?(:rtv_parent_id) && rtv_parent_id
      end

      data
    end

    def deserialize(job_data)
      super(job_data)

      if defined?(RailsTraceViewer) && RailsTraceViewer.enabled
        self.rtv_trace_id  = job_data["rtv_trace_id"]  if job_data.key?("rtv_trace_id")  && respond_to?(:rtv_trace_id=)
        self.rtv_parent_id = job_data["rtv_parent_id"] if job_data.key?("rtv_parent_id") && respond_to?(:rtv_parent_id=)
      end

      self
    end
  end
end
