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
      class_option :database, type: :string, desc: "Database to generate the migration for"

      def validate_resource
        exit unless resource_valid?
      end

      def invoke_migration
        say_status :invoke, :migration, :white
      end

      # rails generate effective:migration courses body:text --database example
      def create_migration
        if invoked_attributes.present?
          args = ["create_#{plural_name}"] + (invokable(invoked_attributes) | timestamps)
          args += ["--database", options['database']] if options['database']
          Rails::Generators.invoke('migration', args)
          return
        end

        return if with_resource_tenant do
          table_name = resource.klass.table_name

          if ActiveRecord::Base.connection.table_exists?(table_name)
            say_status(:error, "#{table_name} table already exist. We can't migrate (yet). Exiting.", :red)
            true
          end
        end

        if resource.model_attributes.blank?
          say_status(:error, "No model attributes present. Please add the effective_resource do ... end block and try again", :red)
          return
        end

        args = ["create_#{plural_name}"] + invokable(resource.model_attributes) - timestamps
        args += ["--database", options['database']] if options['database']

        if options['database'].blank? && defined?(Tenant)
          args += ["--database", resource.klass.name.split('::').first.downcase]
        end

        Rails::Generators.invoke('migration', args)
      end

      protected

      def timestamps
        ['created_at:datetime', 'updated_at:datetime']
      end

    end
  end
end
