# rails generate effective:migration NAME [field[:type] field[:type]] [options]

module Effective
  module Generators
    class MigrationGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a migration.'

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      def create_migration
        Rails::Generators.invoke('migration', ["create_#{plural_name}"] + invoked_attributes)
      end

      def invoked_attributes
        super | ['created_at:datetime', 'updated_at:datetime']
      end

    end
  end
end
