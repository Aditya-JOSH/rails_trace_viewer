module RailsTraceViewer
  module Subscribers
    class MethodSubscriber
      @trace_point = nil

      def self.attach
        return if @trace_point

        @trace_point = TracePoint.trace(:call, :return) do |tp|
          path = tp.path.to_s
          
          is_app_path = path.start_with?(Rails.root.to_s) && 
                        !path.include?("/vendor/") && 
                        !path.include?("rails_trace_viewer")

          is_view_related = path.include?("/app/views/")
          
          # Only trace Controllers, Models, Jobs, Services. Skip Views.
          next unless is_app_path && !is_view_related

          is_active_job = (tp.defined_class < ApplicationJob) rescue false
          is_sidekiq_worker = (tp.defined_class.include?(Sidekiq::Worker)) rescue false

          next unless is_app_path || is_active_job || is_sidekiq_worker

          unless RailsTraceViewer::TraceContext.active?
             trace_id = SecureRandom.uuid
             RailsTraceViewer::TraceContext.start!(trace_id)
             RailsTraceViewer::Collector.start_trace(trace_id)
             parent_id = nil
          else
             trace_id = RailsTraceViewer::TraceContext.trace_id
             parent_id = RailsTraceViewer::TraceContext.parent_id
          end

          if tp.event == :call
            node_id = SecureRandom.uuid
            
            class_name = tp.defined_class.name rescue "Anonymous"
            is_singleton = tp.defined_class.singleton_class? rescue false
            method_sig = "#{class_name}#{is_singleton ? '.' : '#'}#{tp.method_id}"

            arguments = {}
            if tp.binding
              tp.parameters.each do |type, name|
                begin
                  val = tp.binding.local_variable_get(name)
                  if val.is_a?(String)
                    arguments[name] = val.length > 1000 ? val[0..1000] + "... (truncated)" : val
                  elsif val.is_a?(Numeric) || val == true || val == false || val.nil?
                    arguments[name] = val
                  elsif defined?(ActiveRecord::Base) && val.is_a?(ActiveRecord::Base)
                    arguments[name] = val.attributes
                  else
                    inspected = val.inspect
                    arguments[name] = inspected.length > 1000 ? inspected[0..1000] + "... (truncated)" : inspected
                  end
                rescue => e
                  arguments[name] = "Error"
                end
              end
            end
            
            node = {
              id: node_id,
              parent_id: parent_id,
              type: "method",
              name: method_sig,
              source: "#{path.sub(Rails.root.to_s, '')}:#{tp.lineno}",
              file_path: path,
              line_number: tp.lineno,
              class_name: class_name,
              method_name: tp.method_id,
              arguments: arguments,
              children: []
            }
            RailsTraceViewer::Collector.add_node(trace_id, node)
            RailsTraceViewer::TraceContext.push(node_id)

          elsif tp.event == :return
            RailsTraceViewer::TraceContext.pop
          end
        end
      end
    end
  end
end
