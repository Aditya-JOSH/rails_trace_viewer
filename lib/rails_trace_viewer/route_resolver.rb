module RailsTraceViewer
  class RouteResolver
    def self.resolve(path, method)
      recognized = Rails.application.routes.recognize_path(path, method: method.downcase.to_sym)

      route = Rails.application.routes.routes.find do |r|
        r.defaults[:controller] == recognized[:controller] &&
        r.defaults[:action] == recognized[:action]
      end

      {
        name: route&.name || "(unnamed)",
        verb: method,
        path: path
      }
    rescue
      nil
    end
  end
end
