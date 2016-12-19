# rails generate effective:scaffold NAME [field[:type] field[:type]] [options]

# TODO - probably lots

# Generates a migration, model, datatable, routes, controller, views

# rails generate effective:scaffold Thing
# rails generate effective:scaffold admin/thing name:string details:text --actions index show edit update
# rails generate effective:scaffold admin/thing name:string details:text

module Effective
  module Generators
    class ScaffoldGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates an Effective Scaffold'

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'
      class_option :actions, type: :array, default: ['crud'], desc: 'Included actions', banner: 'index show'

      # def create_model
      #   Rails::Generators.invoke('effective:model', [name] + invoked_attributes)
      # end

      # def create_migration
      #   Rails::Generators.invoke('effective:migration', [name] + invoked_attributes)
      # end

      # def create_route
      #   Rails::Generators.invoke('effective:route', [name] + invoked_actions)
      # end

      def create_controller
        Rails::Generators.invoke('effective:controller', [name] + invoked_actions + invoked_attributes_args)
      end

      # def create_datatable
      #   Rails::Generators.invoke('effective:datatable', [name] + invoked_attributes)
      # end

      # def create_views
      #   Rails::Generators.invoke('effective:views', [name] + invoked_actions + invoked_attributes_args)
      # end

      # def create_form
      #   Rails::Generators.invoke('effective:form', [name] + invoked_attributes)
      # end

    end
  end
end

# class_name
# class_path
# file_path



# require "rails/generators/rails/resource/resource_generator"

# module Effective
#   module Generators
#     class ScaffoldGenerator < ResourceGenerator # :nodoc:
#       remove_hook_for :resource_controller
#       remove_class_option :actions

#       class_option :stylesheets, type: :boolean, desc: "Generate Stylesheets"
#       class_option :stylesheet_engine, desc: "Engine for Stylesheets"
#       class_option :assets, type: :boolean
#       class_option :resource_route, type: :boolean
#       class_option :scaffold_stylesheet, type: :boolean

#       def handle_skip
#         @options = @options.merge(stylesheets: false) unless options[:assets]
#         @options = @options.merge(stylesheet_engine: false) unless options[:stylesheets] && options[:scaffold_stylesheet]
#       end

#       hook_for :scaffold_controller, required: true

#       hook_for :assets do |assets|
#         invoke assets, [controller_name]
#       end

#       hook_for :stylesheet_engine do |stylesheet_engine|
#         if behavior == :invoke
#           invoke stylesheet_engine, [controller_name]
#         end
#       end
#     end
#   end
# end
