module RailsTraceViewer
  class Collector
    TRACE_TREES = {}

    @sweeper_started = false
    @mutex = Mutex.new

    class << self
      def start_sweeper!
        return if @sweeper_started

        @sweeper_started = true

        Thread.new do
          Thread.current.name = "RailsTraceViewer-OrphanSweeper"
          loop do
            sleep 3
            sweep_all_orphans
          end
        end
      end

      def start_trace(trace_id)
        @mutex.synchronize do
          TRACE_TREES[trace_id] ||= {
            root: nil,
            index: {},
            orphans: {}
          }
        end
      end

      def add_node(trace_id, node)
        after_broadcasts = []

        @mutex.synchronize do
          after_broadcasts = process_node(trace_id, node)
        end

        after_broadcasts.each(&:call)
      end

      def process_node(trace_id, node)
        after = []
        tree = TRACE_TREES[trace_id]

        unless tree
           tree = { root: nil, index: {}, orphans: {} }
           TRACE_TREES[trace_id] = tree
        end

        id        = node[:id]
        parent_id = node[:parent_id]

        tree[:index][id] = node

        if parent_id.nil?
          tree[:root] ||= node
          after << -> { Broadcaster.emit(trace_id, node) }
          after.concat attach_waiting_children(tree, trace_id, id, node)

        else
          parent = tree[:index][parent_id]

          if parent
            parent[:children] ||= []
            parent[:children] << node

            after << -> { Broadcaster.emit(trace_id, node) }
            after.concat attach_waiting_children(tree, trace_id, id, node)
          elsif node[:type] == "job_perform"
            after << -> { Broadcaster.emit(trace_id, node) }
            
            after.concat attach_waiting_children(tree, trace_id, id, node)
          else
            tree[:orphans][parent_id] ||= []
            tree[:orphans][parent_id] << {
              node: node,
              time: Process.clock_gettime(Process::CLOCK_MONOTONIC)
            }
          end
        end

        after
      end

      def attach_waiting_children(tree, trace_id, parent_id, parent_node)
        return [] unless tree[:orphans][parent_id]

        after = []

        tree[:orphans][parent_id].each do |entry|
          child = entry[:node]
          parent_node[:children] ||= []
          parent_node[:children] << child

          after << -> { Broadcaster.emit(trace_id, child) }

          after.concat attach_waiting_children(tree, trace_id, child[:id], child)
        end

        tree[:orphans].delete(parent_id)
        after
      end

      def sweep_all_orphans
        after = []

        @mutex.synchronize do
          now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          TRACE_TREES.each do |trace_id, tree|
            next if tree[:orphans].empty?

            tree[:orphans].each do |parent_id, entries|
              entries.reject! do |entry|
                if now - entry[:time] > 3
                  orphan = entry[:node]

                  after << -> { Broadcaster.emit(trace_id, orphan) }
                  true
                else
                  false
                end
              end
            end
          end
        end

        after.each(&:call)
      end

      def finalize_trace(trace_id)
        trace = nil

        @mutex.synchronize do
          tree = TRACE_TREES[trace_id]
          return unless tree
          trace = tree[:root]
          TRACE_TREES.delete(trace_id)
        end

        ActionCable.server.broadcast(
          "rails_trace_viewer",
          event: "trace_completed",
          trace: trace
        )
      end
    end
  end
end
