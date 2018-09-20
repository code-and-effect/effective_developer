require 'rails/generators/active_record/migration/migration_generator'

module Effective
  class ResourceMigrator
    attr_accessor :resource  # The class level effective_resource do ... end object

    def initialize(obj)
      @resource = (obj.kind_of?(Effective::Resource) ? obj: Effective::Resource.new(obj))

      unless @resource.respond_to?(:model) && @resource.model.present?
        raise 'expected effective_resource or klass to have an effective_resource do ... end block defined'
      end

      true
    end

    # Writes database migrations automatically based on effective_resources do ... end block
    def migrate!
      table_attributes = resource.table_attributes
      model_attributes = resource.model_attributes

      table_keys = table_attributes.keys
      model_keys = model_attributes.keys

      # Create table
      if table_keys.blank?
        Rails.logger.info "effective_developer migrate #{resource.plural_name}: create table"
        return rails_migrate("create_#{resource.plural_name}", model_attributes)
      end

      # Fields are not in database, but present in model.rb
      if(add_keys = (model_keys - table_keys)).present?
        Rails.logger.info "effective_developer migrate #{resource.plural_name}: add #{add_keys.to_sentence}"
        rails_migrate("add_fields_to_#{resource.plural_name}", model_attributes.slice(*add_keys))
      end

      # Fields are in database, but no longer in our effective_resource do block
      if (remove_keys = (table_keys - model_keys)).present?
        Rails.logger.info "effective_developer migrate #{resource.plural_name}: remove #{remove_keys.to_sentence}"
        rails_migrate("remove_fields_from_#{resource.plural_name}", table_attributes.slice(*remove_keys))
      end
    end

    private

    def rails_migrate(filename, attributes)
      # I don't need to check pending. But if I did:
      #pending = (ActiveRecord::Migration.check_pending! rescue true)
      #ActiveRecord::Tasks::DatabaseTasks.migrate if pending

      args = [filename] + attributes.map { |name, (type, _)| "#{name}:#{type}" }
      options = {}
      config = { destination_root: Rails.root }

      ActiveRecord::Generators::MigrationGenerator.new(args, options, config).invoke_all
      ActiveRecord::Tasks::DatabaseTasks.migrate

      true
    end

  end
end
