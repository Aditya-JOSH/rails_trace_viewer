# Rails Trace Viewer

An educational and debugging tool for Ruby on Rails to visualize the request lifecycle in real-time.

<div align="center">
  <a href="https://youtu.be/Zwg3rROyaH0">
    <img src="https://img.youtube.com/vi/Zwg3rROyaH0/hqdefault.jpg" alt="Watch the Demo" style="width:100%; max-width:600px;">
  </a>
</div>

Rails Trace Viewer provides a beautiful, interactive Call Stack Tree that visualizes how your Rails application processes requests. It traces the flow from the Controller through Models, Views, SQL Queries, and even across process boundaries into Sidekiq Background Jobs.

---

## 🎯 Purpose

This gem is designed for beginners and advanced developers alike to:

- Visualize the **"Magic"**: See exactly what happens when you hit a route.
- **Debug Distributed Traces**: Watch a request enqueue a Sidekiq job and follow that execution into the worker process in a single connected tree.
- **Spot Performance Issues**: Identify N+1 queries, slow renders, or redundant method calls.

---

## ✨ Key Features

- 🔍 **Real-time Visualization**: Traces appear instantly via WebSockets.
- 🧩 **Distributed Tracing**: Seamlessly links Controller actions to Sidekiq Jobs (enqueue & perform).
- 📊 **Deep Inspection**: Click any node to see arguments, SQL binds, file paths, and line numbers.
- 🎨 **Beautiful UI**: Interactive infinite canvas with panning, zooming, and auto-centering.
- 🛑 **Zero Production Impact**: Designed to run safely in development mode.

---

## 📦 Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_trace_viewer', group: :development
```

Then execute:

```bash
bundle install
```

---

## 🔧 Configuration (Crucial)

To enable real-time tracing, you must ensure ActionCable is correctly configured and the engine is mounted.

---

### 1. Setup ActionCable Connection

Create or update `app/channels/application_cable/connection.rb`:

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      if current_user = env['warden'].user
        current_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
```

---

### 2. Mount Routes

Update `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  # Mount Trace Viewer (Development Only)
  if Rails.env.development?
    mount RailsTraceViewer::Engine => '/rails_trace_viewer'
  end

  # Mount ActionCable
  mount ActionCable.server => '/cable'

  # Optional: Mount Sidekiq Web
  mount Sidekiq::Web => '/sidekiq'
end
```

**🛑 Need to disable the gem?** Simply comment out the `mount RailsTraceViewer::Engine => '/rails_trace_viewer'` line above. The gem detects this and **shuts down completely** (Zero Overhead).
---

### 3. Configure Action Cable (Redis)

Update `config/cable.yml`:

```yaml
development:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
```

---

### 4. Environment Configuration

In `config/environments/development.rb`:

```ruby
Rails.application.configure do
  config.log_level = :debug

  # Suppress ActionCable broadcast logs
  config.action_cable.logger = Logger.new(STDOUT)
  config.action_cable.logger.level = Logger::WARN
end
```

---

### 5. Configure Sidekiq

Add to `config/initializers/sidekiq.rb`:

```ruby
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } }
end
```

---

## 🚀 Usage

To see the full power of Rails Trace Viewer:

### 1. Start the Web Server

```bash
rails s
```

### 2. Start Sidekiq (required for job tracing)

```bash
bundle exec sidekiq
```

### 3. Open the Viewer

Visit:

```
http://localhost:3000/rails_trace_viewer
```

### 4. Trigger a Trace

Perform any action in your app (load a page, submit a form, etc.).

If the action enqueues a Sidekiq job, wait for the worker to pick it up.  
You'll see the trace tree expand in real-time.

---

## 🎓 How to Read the Trace

The viewer uses specific colors to represent different parts of the call stack:

- 🟦 **Request** — Incoming HTTP request
- 🟦 **Controller** — Controller action
- ⬜ **Method** — Ruby method call (models, services, helpers)
- 🟨 **SQL** — Database query  
- 🟩 **View** — Rails View or Partial rendering  
- 🟪 **Job Enqueue** — When a background job is scheduled  
- 🟪 **Job Perform** — When Sidekiq executes the job  

💡 **Tip:** Click any node to open the details panel showing:
- File path  
- Line number  
- Method arguments  
- SQL binds  
- And more  

---

## 🛠️ Troubleshooting

### **"My app hangs or loads very slowly when the viewer is open."**
* **Check your Web Server:** Ensure you are using a multi-threaded server like **Puma**.
* **Why?** This gem uses ActionCable (WebSockets). Single-threaded servers (like **WEBrick**) cannot handle the persistent WebSocket connection and regular HTTP requests at the same time, causing the app to block.
* **Fix:** Add `gem 'puma'` to your Gemfile and remove `gem 'webrick'`.

### **"I see the Enqueue node, but the trace stops there."**
- Ensure **Sidekiq is running**.
- Ensure `config/cable.yml` uses **Redis**, not the async adapter.

### **"I see duplicate nodes."**
- Restart the Rails server.  
  This can happen if reloader attaches subscribers twice.

### **"The graph feels jittery."**
- Normal during heavy trace activity.  
- The UI buffers updates every **100ms** to improve smoothness.

---

## 🤝 Contributing

Bug reports and pull requests are welcome at:

https://github.com/Aditya-JOSH/rails_trace_viewer

---

## 📝 License

This gem is available as open source under the terms of the **MIT License**.
