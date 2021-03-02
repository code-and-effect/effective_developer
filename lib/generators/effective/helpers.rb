module Effective
  module Generators
    module Helpers

      protected

      # This is kind of a validate for the resource
      def resource_valid?
        if resource.klass.blank?
          say_status(:error, "Unable to find resource klass from #{name}", :red)
          return false
        end

        true
      end

      def with_resource_tenant(&block)
        if defined?(Tenant) && resource.tenant.present?
          Tenant.as(resource.tenant) { yield }
        else
          yield
        end
      end

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
      # { :name => [:string], ... }
      def invoked_attributes
        if respond_to?(:attributes)
          attributes.inject({}) { |h, att| h[att.name.to_sym] = [att.type]; h }
        else
          Array(options.attributes).compact.inject({}) do |h, att|
            (name, type) = att.split(':')
            h[name.to_sym] = [type.to_sym] if name && type; h
          end
        end
      end

      def invoked_attributes_args
        invoked_attributes.present? ? (['--attributes'] + invokable(invoked_attributes)) : []
      end

      # Turns the GeneratedAttribute or Effective::Attribute into an array of strings
      def invokable(attributes)
        attributes.map { |name, (type, _)| "#{name}:#{type}" }
      end

      def resource_attributes(all: false)
        with_resource_tenant do
          klass_attributes = resource.klass_attributes(all: all)

          if klass_attributes.blank?
            if ActiveRecord::Migration.respond_to?(:check_pending!)
              pending = (ActiveRecord::Migration.check_pending! rescue true)
            else
              pending = ActiveRecord::Migrator.new(:up, ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths)).pending_migrations.present?
            end

            if pending
              migrate = ask("Unable to read the attributes of #{resource.klass || resource.name}. There are pending migrations. Run db:migrate now? [y/n]")
              system('bundle exec rake db:migrate') if migrate.to_s.include?('y')
            end

            klass_attributes = resource.klass_attributes(all: all)
          end

          klass_attributes.presence || resource.model_attributes(all: all)
        end
      end

    end
  end
end
