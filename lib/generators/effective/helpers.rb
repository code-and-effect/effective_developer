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

      # As per the command line invoked actions
      # ['name:string', 'description:text']
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

      # All attributes from the klass. Sorted as per the model Attributes block.
      # ['user_id:integer', name:string', 'description:text']
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

        attribute_names = attributes.keys - [klass.primary_key, 'created_at', 'updated_at']
        attribute_names -= ['site_id'] if klass.respond_to?(:is_site_specific)

        sort_attribute_names(klass, attribute_names).map do |attr|
          if klass.respond_to?(:column_for_attribute) # Rails 4+
            "#{attr}:#{klass.column_for_attribute(attr).try(:type) || 'string'}"
          else
            "#{attr}:#{klass.columns_hash[attr].try(:type) || 'string'}"
          end
        end
      end

      # Written attributes include all belong_tos, as well as
      # any Attributes comments as per our custom 'Attributes' comment block contained in the model file
      # ['user:references', name:string', 'description:text']
      def written_attributes
        @written_attributes ||= (
          attributes = []

          Effective::CodeWriter.new(File.join('app/models', class_path, "#{file_name}.rb")) do |w|
            # belong_tos
            references = w.select { |line| line.start_with?('belongs_to '.freeze) }

            if references.present?
              attributes += w.map(indexes: references) { |line| [[line.scan(/belongs_to\s+:(\w+)/).flatten.first, 'references']] }
            end

            # Attributes
            first = w.find { |line| line == '# Attributes' }
            break unless first

            last = w.find(from: first) { |line| line.start_with?('#') == false && line.length > 0 }
            break unless last

            attributes += w.map(from: first+1, to: last-1) { |line| line.scan(/^\W+(\w+)\W+:(\w+)/).presence }
          end

          attributes.flatten(1).compact.map { |attribute| attribute.join(':') }
        )
      end

      def belongs_tos
        @belongs_tos ||= (
          (class_name.constantize.reflect_on_all_associations(:belongs_to) rescue []).map { |a| a.foreign_key }
        )
      end

      def sort_attribute_names(klass, attribute_names)
        written = written_attributes.reject { |att| att.ends_with?(':references') }.map { |att| att.split(':').first }

        attribute_names.sort do |a, b|
          index = nil

          # belongs_to
          index ||= (
            if belongs_tos.include?(a) && !belongs_tos.include?(b)
              -1
            elsif !belongs_tos.include?(a) && belongs_tos.include?(b)
              1
            end
          )

          # written
          index ||= (
            if written.include?(a) && written.include?(b)
              written.index(a) <=> written.index(b)
            elsif written.include?(a) && !written.include?(b)
              -1
            elsif !written.include?(a) && written.include?(b)
              1
            end
          )

          index || a <=> b
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
        [namespace_path.underscore.presence, plural_name, 'path'].compact.join('_')
      end

      def new_path
        ['new', namespace_path.underscore.presence, singular_name, 'path'].compact.join('_')
      end

      def edit_path
        "edit_#{show_path}"
      end

      def show_path
        [namespace_path.underscore.presence, singular_name, 'path', "(@#{singular_name})"].compact.join('_')
      end

    end
  end
end
