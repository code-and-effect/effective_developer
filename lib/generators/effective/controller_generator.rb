# rails generate effective:controller NAME [action action] [options]

# rails generate effective:controller Thing index show destroy
# rails generate effective:controller Thing --attributes name:string description:text

module Effective
  module Generators
    class ControllerGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a controller in your app/controllers folder.'

      argument :actions, type: :array, default: ['crud'], banner: 'action action'
      class_option :attributes, type: :array, default: [], desc: 'Included permitted params, otherwise read from model'

      def assign_attributes
        @attributes = invoked_attributes.map { |attr| Rails::Generators::GeneratedAttribute.parse(attr) }
        self.class.send(:attr_reader, :attributes)
      end

      def assign_actions
        @actions = invoked_actions
      end

      def create_controller
        binding.pry
        template 'controllers/controller.rb', File.join('app/controllers', class_path, "#{plural_name}_controller.rb")
      end

    end
  end
end
