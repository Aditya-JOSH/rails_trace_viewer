module RailsTraceViewer
  class TraceChannel < ApplicationCable::Channel
    def subscribed
      stream_from "rails_trace_viewer"
    end
  end
end
