module Effective
  module Generators
    module Helpers

      protected

      def invoked_actions
        actions = (respond_to?(:actions) ? self.actions : options.actions)
        actions = Array(actions).flat_map { |arg| arg.gsub('[', '').gsub(']', '').split(',') }

        case actions
        when ['crud']
          %w(index new create show edit update destroy)
        else
          actions
        end
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

      def klass_attributes
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
          puts "Unable to call #{class_name}.new().attributes. Continuing with empty attributes."
          return []
        end

        (attributes.keys - [klass.primary_key, 'created_at', 'updated_at']).map do |attr|
          "#{attr}:#{klass.column_for_attribute(attr).type || 'string'}"
        end
      end

      def parent_class_name
        options[:parent] || (Rails::VERSION::MAJOR > 4 ? 'ApplicationRecord' : 'ActiveRecord::Base')
      end

      # # Always enforce a singlular class_name
      # # scaffold admin/things => Thing
      # # scaffold admin::things => Admin::Thing
      # def class_name
      #   name.include?('::') ? super.singularize : super.singularize.split('::').last
      # end

      # # scaffold admin/thing => ''
      # # scaffold admin::thing => 'admin'
      # def singular_class_path
      #   class_name.include?('::') ? class_path : ''
      # end

      # def singular_name
      #   super.singularize
      # end

      def index_path
        index_helper.sub('_url', '').sub('_path', '') + '_path'
      end

      def edit_path
        edit_helper.sub('_url', '_path')
      end

      def show_path
        show_helper.sub('_url', '_path')
      end

    end
  end
end
