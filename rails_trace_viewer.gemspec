# frozen_string_literal: true

require_relative "lib/rails_trace_viewer/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_trace_viewer"
  spec.version       = RailsTraceViewer::VERSION
  spec.authors       = ["Aditya-JOSH "]
  spec.email         = ["aditya.kolekar91@gmail.com"]

  spec.summary       = "Visualize Rails request flow in real-time."
  spec.description   = "A developer tool that visualizes the lifecycle of a Rails request, including Controller actions, Active Record queries, Active Job enqueues, and Sidekiq executions. Perfect for debugging and education."
  spec.homepage      = "https://github.com/Aditya-JOSH/rails_trace_viewer"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.2.2"
  spec.add_dependency "rails", ">= 7.1", "< 9.0"
  spec.add_dependency "concurrent-ruby", "~> 1.3"
  spec.add_dependency "sidekiq", ">= 6.0", "< 9.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Aditya-JOSH/rails_trace_viewer"
  spec.metadata["changelog_uri"] = "https://github.com/Aditya-JOSH/rails_trace_viewer/blob/main/CHANGELOG.md"

  spec.post_install_message = "Thanks for installing Rails Trace Viewer! Don't forget to mount the engine in your config/routes.rb: mount RailsTraceViewer::Engine => '/rails_trace_viewer'"
  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  end

  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
