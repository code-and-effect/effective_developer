# rails generate effective:migration NAME [field[:type] field[:type]] [options]

# TODO - add default options

# Generates a create_* migration
# rails generate effective:migration Thing
# rails generate effective:migration Thing name:string description:text

module Effective
  module Generators
    class MigrationGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a migration.'

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      def invoke_migration
        say_status :invoke, :migration, :white
      end

      def create_migration
        if invoked_attributes.present?
          Rails::Generators.invoke('migration', ["create_#{plural_name}"] + (invokable(invoked_attributes) | timestamps))
        elsif resource.klass_attributes.present?
          raise 'klass_attributes already exist.  We cant migrate (yet). Exiting.'
        elsif resource.written_attributes.present?
          Rails::Generators.invoke('migration', ["create_#{plural_name}"] + invokable(resource.belong_tos_attributes) + (invokable(resource.written_attributes) | timestamps))
        else
          raise 'You need to specify some attributes or have a model file present'
        end
      end

      protected

      def timestamps
        ['created_at:datetime', 'updated_at:datetime']
      end

    end
  end
end
