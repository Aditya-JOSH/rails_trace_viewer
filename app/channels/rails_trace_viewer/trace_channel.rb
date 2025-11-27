module RailsTraceViewer
  class TraceChannel < ActionCable::Channel::Base
    def subscribed
      stream_from "rails_trace_viewer"
    end
  end
end
