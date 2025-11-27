module RailsTraceViewer
  class Broadcaster
    def self.emit(trace_id, node)
      ActionCable.server.broadcast(
        "rails_trace_viewer",
        {
          trace_id: trace_id,
          node: node
        }
      )
    end
  end
end
