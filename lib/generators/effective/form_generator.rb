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
        @attributes = invoked_attributes.presence || resource_attributes
        self.class.send(:attr_reader, :attributes)
      end

      def invoke_form
        say_status :invoke, :form, :white
      end

      def create_default_form
        if resource.nested_attributes.blank?
          template 'forms/default/_form.html.haml', resource.view_file('form', partial: true)
        end
      end

      def create_tabpanel_form
        if resource.nested_attributes.present?
          template 'forms/tabpanel/_form.html.haml', resource.view_file('form', partial: true)
          template 'forms/tabpanel/_tab_fields.html.haml', resource.view_file("form_#{resource.name}", partial: true)
        end

        class_eval { attr_accessor :attribute }

        resource.nested_attributes.each do |nested_attribute|
          @attribute = nested_attribute
          template 'forms/tabpanel/_tab_nested_attribute.html.haml', resource.view_file("form_#{nested_attribute.name}", partial: true)
          template 'forms/fields/_nested_attribute_fields.html.haml', File.join('app/views', resource.namespace, (resource.namespace.present? ? '' : resource.class_path), nested_attribute.name.to_s.underscore.pluralize, '_fields.html.haml')
        end
      end

      protected

      def form_for
        if resource.namespaces.blank?
          resource.name
        else
          '[' + resource.namespaces.map { |ns| ':' + ns }.join(', ') + ', ' + resource.name + ']'
        end
      end

      def render_field(attribute, depth: 0)
        b = binding
        b.local_variable_set(:attribute, attribute)

        partial = case attribute
        when ActiveRecord::Reflection::BelongsToReflection
          'belongs_to'
        when ActiveRecord::Reflection::HasManyReflection
          'nested_attribute'
        else
          (attribute.type || :string).to_s
        end

        html = ERB.new(
          File.read("#{File.dirname(__FILE__)}/../../scaffolds/forms/fields/_field_#{partial}.html.haml")
        ).result(b).split("\n").map { |line| ('  ' * depth) + line }

        html.length > 1 ? (html.join("\n") + "\n") : html.join
      end

    end
  end
end
