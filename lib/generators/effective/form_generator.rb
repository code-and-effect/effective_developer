# rails generate effective:form NAME [field[:type] field[:type]] [options]

# TODO

# Generates a form
# rails generate effective:form Thing
# rails generate effective:form Thing name:string description:text

# rails generate effective:form Thing --tabbed false

module Effective
  module Generators
    class FormGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a _form.html.haml in your app/views/model/ folder.'

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      def validate_resource
        exit unless resource_valid?
      end

      def assign_attributes
        @attributes = invoked_attributes.presence || resource_attributes
        self.class.send(:attr_reader, :attributes)
      end

      def invoke_form
        say_status :invoke, :form, :white
      end

      def create_form
        with_resource_tenant do
          if admin_effective_scaffold?
            template "#{scaffold_path}/views/_form.html.haml", resource.admin_effective_view_file('form', partial: true)
            template "#{scaffold_path}/views/_form_resource.html.haml", resource.admin_effective_view_file("form_#{resource.name}", partial: true)
          elsif effective_scaffold?
            template "#{scaffold_path}/views/_form_resource.html.haml", resource.view_file("form", partial: true)
          else
            template "#{scaffold_path}/views/_form.html.haml", resource.view_file('form', partial: true)
            template "#{scaffold_path}/views/_form_resource.html.haml", resource.view_file("form_#{resource.name}", partial: true)
          end

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

        b.local_variable_set(:resource, resource)

        partial = case attribute
        when (ActiveRecord::Reflection::BelongsToReflection rescue false)
          b.local_variable_set(:reference, attribute)
          'belongs_to'
        when (ActiveRecord::Reflection::HasManyReflection rescue false)
          b.local_variable_set(:nested_resource, attribute)
          'nested_resource'
        when Effective::Resource
          b.local_variable_set(:nested_resource, attribute)
          'nested_resource'
        else # [:name, [:string]]
          name = attribute.first.to_s
          datatype = ((attribute.last || []).first || :string).to_s

          b.local_variable_set(:attribute, name)

          if datatype == 'string' && (resource.klass || NilClass).const_defined?(name.pluralize.upcase)
            attribute_constant = "#{resource.klass.name}::#{name.pluralize.upcase}"
            b.local_variable_set(:attribute_constant, attribute_constant)

            'select_constant'
          elsif datatype == :string && (resource.klass || NilClass).const_defined?(name.singularize.upcase)
            attribute_constant = "#{resource.klass.name}::#{name.singularize.upcase}"
            b.local_variable_set(:attribute_constant, attribute_constant)

            'select_constant'
          elsif name.include?('price')
            'price'
          elsif name.include?('_url')
            'url'
          elsif name.include?('email')
            'email'
          else
            datatype
          end
        end

        html = ERB.new(
          File.read("#{File.dirname(__FILE__)}/../../scaffolds/fields/_field_#{partial}.html.haml")
        ).result(b).split("\n").map { |line| ('  ' * depth) + line }

        html.length > 1 ? (html.join("\n") + "\n") : html.join
      end

    end
  end
end
