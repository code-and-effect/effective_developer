# rails generate effective:controller Thing [action action] [options]
# rails generate controller NAME [action action] [options]

module Effective
  module Generators
    class MigrationGenerator < Rails::Generators::NamedBase
      desc "Creates a migration"

      source_root File.expand_path(('../' * 4) + 'app/scaffolds', __FILE__)

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      def create_migration
        Rails::Generators.invoke('migration', ["create_#{file_name.pluralize}"] + attributes_as_arguments)
      end

      protected

      def attributes_as_arguments
        attributes.map { |att| "#{att.name}:#{att.type}" }
      end

    end
  end
end
