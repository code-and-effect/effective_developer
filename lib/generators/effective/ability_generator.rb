# rails generate effective:ability NAME [action action] [options]

# Adds a route to app/models/ability.rb
# rails generate effective:ability Thing
# rails generate effective:ability Thing index edit create

module Effective
  module Generators
    class AbilityGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a CanCanCan ability.'

      argument :actions, type: :array, default: ['crud'], banner: 'action action'

      def invoke_ability
        say_status :invoke, :ability, :white
      end

      def create_ability
        unless File.exists?('app/models/ability.rb')
          say_status(:skipped, :ability, :yellow) and return
        end

        Effective::CodeWriter.new('app/models/ability.rb') do |w|
          if w.find { |line, depth| depth == 2 && line == ability }
            say_status :identical, ability, :blue
          else
            w.insert_into_first(ability) { |line, depth| line.start_with?('def initialize') }
          end
        end
      end

      private

      def ability
        @ability ||= (
          abilities = []

          if (crud_actions - invoked_actions).present?
            abilities += (crud_actions & invoked_actions)
          end

          if non_crud_actions.present?
            abilities += non_crud_actions
          end

          abilities = ['manage'] if abilities.blank? || abilities == (crud_actions - ['show'])

          if abilities.length == 1
            abilities = ":#{abilities.first}"
          else
            abilities = '[' + abilities.map { |action| ':' + action }.join(', ') + ']'
          end

          "can #{abilities}, #{resource.class_name}"
        )
      end
    end
  end
end
