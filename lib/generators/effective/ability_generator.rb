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

      def validate_resource
        exit unless resource_valid?
      end

      def invoke_ability
        say_status :invoke, :ability, :white
      end

      def create_ability
        unless File.exist?(resource.abilities_file)
          say_status(:skipped, :ability, :yellow) and return
        end

        Effective::CodeWriter.new(resource.abilities_file) do |w|
          if w.find { |line, depth| (depth == 2 || depth == 3) && line == ability }
            say_status :identical, ability, :blue
          else
            w.insert_into_first(ability + "\n") { |line, depth| line.start_with?('def initialize') || line.end_with?('abilities(user)') }

            say_status :ability, ability
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

          abilities = ['crud'] if abilities.blank? || abilities == (crud_actions - ['show'])

          if abilities == ['crud']
            abilities = "#{abilities.first}"
          elsif abilities.length == 1
            abilities = ":#{abilities.first}"
          else
            abilities = '[' + abilities.map { |action| ':' + action }.join(', ') + ']'
          end

          name = if resource.module_name.present?
            resource.class_name.split('::').last
          else
            resource.class_name
          end

          "can(#{abilities}, #{name})"
        )
      end
    end
  end
end
