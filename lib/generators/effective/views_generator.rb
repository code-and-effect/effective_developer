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
        @attributes = invoked_attributes.presence || resource_attributes
        self.class.send(:attr_reader, :attributes)
      end

      def invoke_views
        say_status :invoke, :views, :white
      end

      def create_views
        (invoked_actions & available_actions).each do |action|
          template "views/#{action}.html.haml", resource.view_file(action)
        end

        if invoked_actions.include?('show') || non_crud_actions.present?
          template 'views/_resource.html.haml', resource.view_file(resource.name, partial: true)
        end
      end

      private

      def available_actions
        %w(index new show edit)
      end

    end
  end
end
