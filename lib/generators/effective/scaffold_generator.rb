# rails generate effective:scaffold NAME [field[:type] field[:type]] [options]

# rails generate effective:scaffold Thing
# rails generate effective:scaffold admin/thing name:string details:text --actions index show edit update
# rails generate effective:scaffold admin/thing name:string details:text --actions crud-show
# rails generate effective:scaffold admin/thing name:string details:text

module Effective
  module Generators
    class ScaffoldGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates an Effective Scaffold'

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'
      class_option :actions, type: :array, default: ['crud'], desc: 'Included actions', banner: 'index show'

      def invoke_model
        if File.exists?(resource.model_file)
          say_status(:skipped, :model, :yellow) and return
        end

        Rails::Generators.invoke('effective:model', [name] + invokable(invoked_attributes))
      end

      def invoke_migration
        Rails::Generators.invoke('effective:migration', [name] + invokable(invoked_attributes))
      end

      def invoke_controller
        Rails::Generators.invoke('effective:controller', [name] + invoked_actions + invoked_attributes_args)
      end

      def invoke_route
        Rails::Generators.invoke('effective:route', [name] + invoked_actions)
      end

      def invoke_ability
        Rails::Generators.invoke('effective:ability', [name] + invoked_actions)
      end

      def invoke_menu
        Rails::Generators.invoke('effective:menu', [name])
      end

      def invoke_datatable
        unless invoked_actions.include?('index')
          say_status(:skipped, :datatable, :yellow) and return
        end

        Rails::Generators.invoke('effective:datatable', [name] + invoked_actions + invoked_attributes_args)
      end

      def invoke_views
        Rails::Generators.invoke('effective:views', [name] + invoked_actions + invoked_attributes_args)
      end

      def invoke_form
        unless invoked_actions.include?('new') || invoked_actions.include?('edit')
          say_status(:skipped, :form, :yellow) and return
        end

        Rails::Generators.invoke('effective:form', [name] + invokable(invoked_attributes))
      end

    end
  end
end
