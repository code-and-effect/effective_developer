# rails generate effective:form NAME [field[:type] field[:type]] [options]

# TODO

# Generates a form
# rails generate effective:form Thing
# rails generate effective:form Thing name:string description:text

module Effective
  module Generators
    class FormGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a _form.html.haml in your app/views/model/ folder.'

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      def assign_attributes
        @attributes = (invoked_attributes.presence || klass_attributes).map do |attribute|
          Rails::Generators::GeneratedAttribute.parse(attribute)
        end
      end

      def invoke_form
        say_status :invoke, :form, :white
      end

      def create_default_form
        if has_manys.blank?
          template 'forms/default/_form.html.haml', File.join('app/views', namespace_path, (namespace_path.present? ? '' : class_path), plural_name, '_form.html.haml')
        end
      end

      def create_tabpanel_form
        if has_manys.present?
          template 'forms/tabpanel/_form.html.haml', File.join('app/views', namespace_path, (namespace_path.present? ? '' : class_path), plural_name, '_form.html.haml')
          template 'forms/tabpanel/_tab_fields.html.haml', File.join('app/views', namespace_path, (namespace_path.present? ? '' : class_path), plural_name, '_form_fields.html.haml')
        end

        class_eval { attr_accessor :attribute }

        has_manys.each do |has_many|
          @attribute = Rails::Generators::GeneratedAttribute.parse("#{has_many}")
          template 'forms/tabpanel/_tab_has_many.html.haml', File.join('app/views', namespace_path, (namespace_path.present? ? '' : class_path), plural_name, "_form_#{has_many}.html.haml")
          template 'forms/fields/_nested_fields.html.haml', File.join('app/views', namespace_path, (namespace_path.present? ? '' : class_path), has_many.to_s.underscore.pluralize, "_fields.html.haml")
        end
      end

      protected

      def form_for
        if namespaces.blank?
          singular_name
        else
          '[' + namespaces.map { |ns| ':' + ns }.join(', ') + ', ' + singular_name + ']'
        end
      end

      def render_field(attribute, depth: 0)
        b = binding
        b.local_variable_set(:attribute, attribute)

        partial = nil
        partial = 'belongs_to' if belongs_tos.include?(attribute.name)
        partial = 'has_many' if has_manys.include?(attribute.name)

        partial ||= case attribute.type
          when :integer   ; 'integer'
          when :datetime  ; 'datetime'
          when :date      ; 'date'
          when :text      ; 'text'
          else 'string'
        end

        html = ERB.new(
          File.read("#{File.dirname(__FILE__)}/../../scaffolds/forms/fields/_field_#{partial}.html.haml")
        ).result(b).split("\n").map { |line| ('  ' * depth) + line }

        html.length > 1 ? (html.join("\n") + "\n") : html.join
      end

    end
  end
end
