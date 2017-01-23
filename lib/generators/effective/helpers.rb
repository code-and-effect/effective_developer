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

      # def belongs_tos
      #   @belongs_tos ||= (
      #     (class_name.constantize.reflect_on_all_associations(:belongs_to) rescue []).map { |a| a.foreign_key }
      #   )
      # end

      # def nested_attributes
      #   @nested_attributes ||= (
      #     (class_name.constantize.reflect_on_all_autosave_associations.map { |a| a.name.to_s } - ['regions', 'addresses']).sort
      #   )
      # end

      # def action_path(name, at: true)
      #   name.to_s.underscore + '_' + show_path(at: at)
      # end

      # def index_path
      #   [namespace_path.underscore.presence, plural_name, 'path'].compact.join('_')
      # end

      # def new_path
      #   ['new', namespace_path.underscore.presence, singular_name, 'path'].compact.join('_')
      # end

      # def edit_path
      #   "edit_#{show_path}"
      # end

      # def show_path(at: true)
      #   [namespace_path.underscore.presence, singular_name, 'path'].compact.join('_') + "(#{'@' if at}#{singular_name})"
      # end

    end
  end
end
