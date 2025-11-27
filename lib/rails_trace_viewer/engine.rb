module RailsTraceViewer
  class Engine < ::Rails::Engine
    isolate_namespace RailsTraceViewer

    initializer "rails_trace_viewer.subscribe", after: :load_config_initializers do
      ActiveSupport.on_load(:action_controller) do
        RailsTraceViewer::Subscribers::ControllerSubscriber.attach
      end

      ActiveSupport.on_load(:active_record) do
        RailsTraceViewer::Subscribers::SqlSubscriber.attach
      end

      ActiveSupport.on_load(:action_view) do
        RailsTraceViewer::Subscribers::ViewSubscriber.attach
      end

      ActiveSupport.on_load(:active_job) do
        RailsTraceViewer::Subscribers::ActiveJobSubscriber.attach
      end

      Rails.application.reloader.to_prepare do
        RailsTraceViewer::Subscribers::SidekiqSubscriber.attach
        RailsTraceViewer::Subscribers::MethodSubscriber.attach
      end
    end
    
    initializer "rails_trace_viewer.start_sweeper" do
      RailsTraceViewer::Collector.start_sweeper!
    end
  end
end
