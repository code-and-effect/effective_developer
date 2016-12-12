# rails generate effective:controller Thing [action action] [options]
# rails generate controller NAME [action action] [options]

module Effective
  module Generators
    class RouteGenerator < Rails::Generators::NamedBase
      desc "Creates a route"

      def create_route
        Rails::Generators.invoke('resource_route', [name])
      end

    end
  end
end
