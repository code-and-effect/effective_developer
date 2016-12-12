# rails generate effective:scaffold Thing

module Effective
  module Generators
    class ScaffoldGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      desc 'Creates an Effective Scaffold'

      argument :name, type: :string, default: nil
      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      #class_option :migration, type: :boolean, default: true

      source_root File.expand_path(('../' * 4) + 'app/scaffolds', __FILE__)

      def create_migration
        Rails::Generators.invoke('migration', ["create_#{file_name.pluralize}"] + attributes_as_arguments)
      end

      def create_model
        template 'models/model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      end

      def create_routes
        Rails::Generators.invoke('resource_route', [name])
      end

      def create_controller
        Rails::Generators.invoke('effective:controller', [name])
      end

      protected

      # Used by the migration template to determine the parent name of the model
      def parent_class_name
        options[:parent] || 'ApplicationRecord'
      end

      def attributes_as_arguments
        attributes.map { |att| "#{att.name}:#{att.type}" }
      end


      # def self.next_migration_number(dirname)
      #   next_migration_number = current_migration_number(dirname) + 1
      #   ActiveRecord::Migration.next_migration_number(next_migration_number)
      # end

      # def primary_key_type
      #   key_type = options[:primary_key_type]
      #   ", id: :#{key_type}" if key_type
      # end

      # def create_migration_file
      #   return unless options[:migration]
      #   migration_template 'migrations/create_table_migration.rb', "db/migrate/create_#{table_name}.rb"
      # end

      # def create_model
      #   template 'models/model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      # end


      # def create_migration
      #   atts = attributes.map { |att| "#{att.name}:#{att.type}" }
      #   Rails::Generators.invoke('active_record:model', [name] + atts, {migration: true, timestamps: true})
      # end



      # hook_for :orm, required: true, desc: 'ORM to be invoked' do |invoked|
      #   binding.pry
      # end

      #hook_for :template_engine # HAML

      # hook_for :helper, as: :scaffold do |invoked|
      #   invoke invoked, [controller_name]
      # end


      # hook_for :template_engine, :test_framework, as: :scaffold


      # def create_migration_file
      #   return unless options[:migration]
      #   migration_template 'migrations/create_table_migration.rb', "db/migrate/create_#{table_name}.rb"
      # end

      # def create_model
      #   template 'models/model.rb', "app/models/#{file_name}.rb"
      # end

      # def self.next_migration_number(thing)
      #   123
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
