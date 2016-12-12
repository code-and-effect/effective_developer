module Effective
  module Generators
    module Helpers

      protected

      def invoked_attributes
        _attributes = (respond_to?(:attributes) ? attributes : Array(options.attributes).compact)
        _attributes.map { |att| "#{att.name}:#{att.type}" }
      end

      def invoked_actions
        _actions = (respond_to?(:actions) ? actions : options.actions)
        _actions = Array(_actions).flat_map { |arg| arg.gsub('[', '').gsub(']', '').split(',') }

        case _actions
        when ['crud']
          %w(index new create show edit update destroy)
        else
          _actions
        end
      end

      # Used by model and datatable
      def parent_class_name
        options[:parent] || 'ApplicationRecord'
      end

    end
  end
end
