# rails generate effective:views NAME [action action] [options]

# Generates a view
# rails generate effective:views Thing
# rails generate effective:views Thing index show new
# rails generate effective:views Thing index show --attributes name:string description:text

module Effective
  module Generators
    class ViewsGenerator < Rails::Generators::NamedBase
      include Helpers
      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates views in your app/views folder.'

      argument :actions, type: :array, default: ['crud'], banner: 'action action'
      class_option :attributes, type: :array, default: [], desc: 'Included form attributes, otherwise read from model'

      def assign_attributes
        @attributes = (invoked_attributes.presence || klass_attributes).map do |attribute|
          Rails::Generators::GeneratedAttribute.parse(attribute)
        end

        self.class.send(:attr_reader, :attributes)
      end

      def create_views
        (invoked_actions & available_actions).each do |action|
          template "views/#{action}.html.haml", File.join('app/views', file_path.pluralize, "#{action}.html.haml")
        end
      end

      private

      def available_actions
        %w(index new show edit)
      end

    end
  end
end
