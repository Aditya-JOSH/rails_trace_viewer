# lib/rails_trace_viewer.rb
require "rails"
require "active_support"
require "active_support/notifications"

require "rails_trace_viewer/engine"
require "rails_trace_viewer/collector"
require "rails_trace_viewer/trace_context"
require "rails_trace_viewer/broadcaster"
require "rails_trace_viewer/job_link_registry"
require "rails_trace_viewer/route_resolver"

require "rails_trace_viewer/subscribers/controller_subscriber"
require "rails_trace_viewer/subscribers/sql_subscriber"
require "rails_trace_viewer/subscribers/view_subscriber"
require "rails_trace_viewer/subscribers/active_job_subscriber"
require "rails_trace_viewer/subscribers/sidekiq_subscriber"
require "rails_trace_viewer/subscribers/method_subscriber"

module RailsTraceViewer
  mattr_accessor :enabled
  self.enabled = true

  def self.enabled?
    !!self.enabled
  end

  def self.configure
    yield self
  end
end
