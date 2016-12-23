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

      def create_form
        template 'forms/_form.html.haml', File.join('app/views', namespace_path, (namespace_path.present? ? '' : class_path), plural_name, '_form.html.haml')
      end

      protected

      def form_for
        if namespaces.blank?
          singular_name
        else
          '[' + namespaces.map { |ns| ':' + ns }.join(', ') + ', ' + singular_name + ']'
        end
      end

    end
  end
end
