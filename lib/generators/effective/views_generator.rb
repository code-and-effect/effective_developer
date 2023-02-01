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

      def validate_resource
        exit unless resource_valid?
      end

      def assign_attributes
        @attributes = (invoked_attributes.presence || resource_attributes).except(:archived)
        self.class.send(:attr_reader, :attributes)
      end

      def invoke_views
        say_status :invoke, :views, :white
      end

      def create_views
        if invoked_actions.include?('show') || non_crud_actions.present?
          if admin_effective_scaffold?
            template "#{scaffold_path}/views/_resource.html.haml", resource.admin_effective_view_file(resource.name, partial: true)
          else
            template "#{scaffold_path}/views/_resource.html.haml", resource.view_file(resource.name, partial: true)
          end
        end

        if effective_scaffold?
          template "#{scaffold_path}/views/_layout.html.haml", resource.view_file('layout', partial: true)
        end

      end

    end
  end
end
