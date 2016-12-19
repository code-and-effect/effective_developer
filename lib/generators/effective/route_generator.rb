# rails generate effective:route NAME [action action] [options]

# TODO - support actions

# Adds a route to config/routes.rb
# rails generate effective:route Thing
# rails generate effective:model Thing index edit create

module Effective
  module Generators
    class RouteGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a route.'

      argument :actions, type: :array, default: ['crud'], banner: 'action action'

      def create_route
        Rails::Generators.invoke('resource_route', [[namespace_path.presence, plural_name].compact.join('/')])
      end

    end
  end
end
