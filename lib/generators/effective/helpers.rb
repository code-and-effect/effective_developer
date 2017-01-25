module Effective
  module Generators
    module Helpers

      protected

      def resource
        @resource ||= Effective::Resource.new(name)
      end

      def crud_actions
        %w(index new create show edit update destroy)
      end

      def non_crud_actions
        invoked_actions - crud_actions
      end

      # --actions crud another
      # --actions crud-show another
      def invoked_actions
        actions = (respond_to?(:actions) ? self.actions : options.actions)
        actions = Array(actions).flat_map { |arg| arg.gsub('[', '').gsub(']', '').split(',') }

        crudish = actions.find { |action| action.start_with?('crud') }

        if crudish
          actions = crud_actions + (actions - [crudish])
          crudish.split('-').each { |except| actions.delete(except) }
        end

        actions
      end

      # As per the command line invoked actions. These are Rails Generated Attributes
      def invoked_attributes
        if respond_to?(:attributes)
          attributes
        else
          Array(options.attributes).compact.map { |att| Rails::Generators::GeneratedAttribute.parse(att) }
        end
      end

      def invoked_attributes_args
        invoked_attributes.present? ? (['--attributes'] + invokable(invoked_attributes)) : []
      end

      # Turns the GeneratedAttribute or Effective::Attribute into an array of strings
      def invokable(attributes)
        attributes.map { |att| "#{att.name}:#{att.type}" }
      end

      def resource_attributes
        klass_attributes = resource.klass_attributes

        if klass_attributes.blank?
          if ActiveRecord::Migrator.new(:up, ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths)).pending_migrations.present?
            migrate = ask("Unable to read the attributes of #{resource.klass || resource.name}. There are pending migrations. Run db:migrate now? [y/n]")
            system('bundle exec rake db:migrate') if migrate.to_s.include?('y')
          end

          klass_attributes = resource.klass_attributes
        end

        klass_attributes.presence || resource.written_attributes
      end

    end
  end
end
