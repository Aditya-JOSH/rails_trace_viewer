module RailsTraceViewer
  class Engine < ::Rails::Engine
    isolate_namespace RailsTraceViewer

    initializer "rails_trace_viewer.active_job_extension" do
      ActiveSupport.on_load(:active_job) do
        include RailsTraceViewer::ActiveJobExtension
      end
    end

    class << self
      def enable_tracing!
        return if @tracing_initialized

        if Rails.application.routes.routes.empty?
          Rails.application.reload_routes!
        end

        is_mounted = Rails.application.routes.routes.any? do |route|
          app = route.app
          while app.respond_to?(:app) && app != app.app
            app = app.app
          end

          match_class = (app == RailsTraceViewer::Engine) ||
                        app.to_s.include?("RailsTraceViewer::Engine")

          path_match = (route.path.spec.to_s rescue "")
                         .include?("/rails_trace_viewer")

          match_class || path_match
        end

        if is_mounted
          RailsTraceViewer.enabled = true

          unless @booted_message_shown
            puts "✅ [RailsTraceViewer] Engine mounted. Tracing is ACTIVE."
            @booted_message_shown = true
          end

          RailsTraceViewer::Subscribers::ControllerSubscriber.attach
          RailsTraceViewer::Subscribers::SqlSubscriber.attach
          RailsTraceViewer::Subscribers::ViewSubscriber.attach
          RailsTraceViewer::Subscribers::ActiveJobSubscriber.attach
          RailsTraceViewer::Subscribers::SidekiqSubscriber.attach if defined?(Sidekiq)
          RailsTraceViewer::Subscribers::MethodSubscriber.attach

          RailsTraceViewer::Collector.start_sweeper!
          
        else
          RailsTraceViewer.enabled = false

          unless @booted_message_shown
            puts "🚫 [RailsTraceViewer] Engine route not found. Tracing DISABLED (Zero Overhead)."
            @booted_message_shown = true
          end
        end

        @tracing_initialized = true
      end
    end

    config.to_prepare do
      RailsTraceViewer::Engine.enable_tracing!
    end

    console do
      RailsTraceViewer::Engine.enable_tracing!
    end
  end
end
