module Effective
  module Generators
    module Helpers

      protected

      def invoked_attributes
        if respond_to?(:attributes) && attributes.first.kind_of?(Rails::Generators::GeneratedAttribute)
          attributes.map { |att| "#{att.name}:#{att.type}" }
        else
          Array(options.attributes).compact
        end
      end

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

      # Used by model and datatable
      def parent_class_name
        options[:parent] || (Rails::VERSION::MAJOR > 4 ? 'ApplicationRecord' : 'ActiveRecord::Base')
      end

      # The built in singular_name doesn't seem to do the right thing
      def singular_name
        super.singularize
      end

      def singular_class_name
        class_name.singularize
      end

      def plural_class_name
        class_name.pluralize
      end

      def max_attribute_name_length
        @max_attribute_name_length ||= (attributes.map { |att| att.name.length }.max || 0)
      end

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
