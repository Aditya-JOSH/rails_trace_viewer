module RailsTraceViewer
  class RouteResolver
    def self.resolve(path, method)
      http_verb = method.to_s.downcase.to_sym

      recognized = Rails.application.routes.recognize_path(path, method: http_verb)

      route = Rails.application.routes.routes.find do |r|
        r.defaults[:controller] == recognized[:controller] &&
        r.defaults[:action] == recognized[:action]
      end

      {
        name: route&.name || "(unnamed)",
        verb: method,
        path: path
      }
    rescue StandardError
      {
        name: "(unrecognized)",
        verb: method,
        path: path
      }
    end
  end
end
