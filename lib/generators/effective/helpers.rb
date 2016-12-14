module Effective
  module Generators
    module Helpers

      protected

      def invoked_attributes
        attributes = (respond_to?(:attributes) ? self.attributes : Array(options.attributes).compact)
        attributes.map { |att| "#{att.name}:#{att.type}" }
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

      def max_attribute_name_length
        @max_attribute_name_length ||= (attributes.map { |att| att.name.length }.max || 0)
      end

    end
  end
end
