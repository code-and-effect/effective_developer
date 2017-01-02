module Effective
  module Generators
    module Helpers

      protected

      def crud_actions
        %w(index new create show edit update destroy)
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

      def invoked_attributes
        if respond_to?(:attributes)
          attributes.map { |att| "#{att.name}:#{att.type}" }
        else
          Array(options.attributes).compact
        end
      end

      def invoked_attributes_args
        invoked_attributes.present? ? (['--attributes'] + invoked_attributes) : []
      end

      def klass_attributes(verbose: true)
        klass = class_name.safe_constantize
        return [] unless klass

        begin
          attributes = klass.new().attributes
        rescue ActiveRecord::StatementInvalid => e
          pending = ActiveRecord::Migrator.new(:up, ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths)).pending_migrations.present?

          if e.message.include?('PG::UndefinedTable') && pending
            migrate = ask("Unable to read the attributes of #{class_name}. There are pending migrations. Run db:migrate now? [y/n]")
            system('bundle exec rake db:migrate') if migrate.to_s.include?('y')
          end
        end

        begin
          attributes = klass.new().attributes
        rescue => e
          puts "Unable to call #{class_name}.new().attributes. Continuing with empty attributes." if verbose
          return []
        end

        (attributes.keys - [klass.primary_key, 'created_at', 'updated_at']).map do |attr|
          "#{attr}:#{klass.column_for_attribute(attr).type || 'string'}"
        end
      end

      def parent_class_name
        options[:parent] || (Rails::VERSION::MAJOR > 4 ? 'ApplicationRecord' : 'ActiveRecord::Base')
      end

      # We handle this a bit different than the regular scaffolds
      def assign_names!(name)
        @class_path = (name.include?('/') ? name[(name.rindex('/')+1)..-1] : name).split('::')
        @class_path.map!(&:underscore)
        @class_path[@class_path.length-1] = @class_path.last.singularize # Always singularize
        @file_name = @class_path.pop
      end

      def namespaces
        @namespaces ||= namespace_path.split('/')
      end

      # admin/effective::things => 'admin'
      # effective::things => ''
      def namespace_path
        name.include?('/') ? name[0...name.rindex('/')] : ''
      end

      def namespaced_class_name
        if name.include?('/')
          name[0...name.rindex('/')].classify + '::' + singular_name.classify.pluralize
        else
          singular_name.classify.pluralize
        end
      end

      def index_path
        [namespace_path.underscore.presence, plural_name].compact.join('_') + '_path'
      end

      def new_path
        ['new', namespace_path.underscore.presence, singular_name].compact.join('_') + '_path'
      end

      def edit_path
        "edit_#{show_path}"
      end

      def show_path
        [namespace_path.underscore.presence, singular_name].compact.join('_') + "_path(@#{singular_name})"
      end

    end
  end
end
