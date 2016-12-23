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

      def create_ability
        Effective::CodeWriter.new('app/models/ability.rb') do |w|
          if namespaces.blank?
            w.insert_after_last(ability) { |line, depth| depth == 2 && line.start_with?('can ') } ||
            w.insert_before_last(ability) { |line, depth| depth == 2 && line.start_with?('if') } ||
            w.insert_before_last(ability) { |line, depth| depth == 2 && line == 'end' }

            say_status :ability, ability
          end

          namespaces.each do |namespace|
            w.within("if user.is?(:#{namespace})") do
              w.insert_after_last(ability) { |line, depth| depth == 1 && line.start_with?('can ') } ||
              w.insert_before_last(ability) { |line, depth| depth == 1 && line == 'end' }

              say_status "#{namespace}_ability", ability
            end
          end
        end
      end

      private

      def namespaces
        @namespaces ||= namespace_path.split('/')
      end

      def ability
        @ability ||= (
          abilities = []

          if (crud_actions - invoked_actions).present?
            abilities += (crud_actions & invoked_actions)
          end

          if (invoked_actions - crud_actions).present?
            abilities += (invoked_actions - crud_actions)
          end

          abilities = ['manage'] if abilities.blank?

          if abilities.length == 1
            abilities = ":#{abilities.first}"
          else
            abilities = '[' + abilities.map { |action| ':' + action }.join(', ') + ']'
          end

          "can #{abilities}, #{class_name}"
        )
      end
    end
  end
end
