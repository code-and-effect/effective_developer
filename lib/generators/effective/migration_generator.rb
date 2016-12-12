# rails generate effective:migration NAME [field[:type] field[:type]] [options]

module Effective
  module Generators
    class MigrationGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'app/scaffolds', __FILE__)

      desc 'Creates a migration.'

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      def create_migration
        Rails::Generators.invoke('migration', ["create_#{file_name.pluralize}"] + invoked_attributes)
      end

    end
  end
end
