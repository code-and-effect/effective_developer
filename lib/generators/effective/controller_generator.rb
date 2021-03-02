# rails generate effective:controller NAME [action action] [options]

# Generates a controller
# rails generate effective:controller Thing
# rails generate effective:controller Thing index edit create
# rails generate effective:controller Thing index edit create --attributes name:string description:text

module Effective
  module Generators
    class ControllerGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a controller in your app/controllers folder.'

      argument :actions, type: :array, default: ['crud'], banner: 'action action'
      class_option :attributes, type: :array, default: [], desc: 'Included permitted params, otherwise read from model'

      def validate_resource
        exit unless resource_valid?
      end

      def assign_actions
        @actions = invoked_actions
      end

      def assign_attributes
        @attributes = invoked_attributes.presence || resource.belong_tos_attributes.merge(resource_attributes)
        self.class.send(:attr_reader, :attributes)
      end

      def invoke_controller
        say_status :invoke, :controller, :white
      end

      def create_controller
        template 'controllers/controller.rb', resource.controller_file
      end

    end
  end
end
