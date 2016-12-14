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

      def assign_actions
        @actions = invoked_actions
      end

      def assign_attributes
        @attributes = (invoked_attributes.presence || klass_attributes).map do |attribute|
          Rails::Generators::GeneratedAttribute.parse(attribute)
        end

        self.class.send(:attr_reader, :attributes)
      end

      def create_controller
        template 'controllers/controller.rb', File.join('app/controllers', class_path, "#{plural_name}_controller.rb")
      end

      protected

      def permitted_param_for(attribute_name)
        case attribute_name
        when 'roles'
          'roles: EffectiveRoles.permitted_params'
        else
          ':' + attribute_name
        end
      end

    end
  end
end
