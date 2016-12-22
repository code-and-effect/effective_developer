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
        blocks = []

        Effective::CodeWriter.new('config/routes.rb') do |w|
          namespaces.each do |namespace|
            index = nil

            w.within(blocks.last) do
              index = w.first { |line, depth| depth == 1 && line == namespace }
            end

            index ? (blocks << index) : break
          end

          content = namespaces[blocks.length..-1] + [resources].flatten + (['end'] * (namespaces.length - blocks.length))

          w.within(blocks.last) do
            w.insert_after_last(content) { |line, depth| depth == 1 && line.start_with?('resources') } ||
            w.insert_before_last(content) { |line, depth| depth == 1 && line.start_with?('root') } ||
            w.insert_before_last(content) { |line, depth| line == 'end' }
          end
        end
      end

      private

      def namespaces
        @namespaces ||= namespace_path.split('/').map { |namespace| "namespace :#{namespace} do"}
      end

      def resources
        @resources ||= (
          resources = "resources :#{plural_name}"

          if (crud_actions - invoked_actions).present?
            resources << ', only: ['
            resources << (crud_actions & invoked_actions).map { |action| ':' + action }.join(', ')
            resources << ']'
          end

          if (invoked_actions - crud_actions).present?
            [resources + ' do'] + (invoked_actions - crud_actions).map { |action| "get :#{action}, on: :member" } + ['end']
          else
            resources
          end
        )
      end

    end
  end
end
