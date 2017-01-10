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

      def render_field(attribute, depth: 1)
        b = binding
        b.local_variable_set(:attribute, attribute)

        partial = nil
        partial = 'belongs_to' if belongs_tos.include?(attribute.name)

        partial ||= case attribute.type
          when :integer   ; 'integer'
          when :datetime  ; 'datetime'
          when :date      ; 'date'
          when :text      ; 'text'
          else 'string'
        end

        ERB.new(
          File.read("#{File.dirname(__FILE__)}/../../scaffolds/forms/_field_#{partial}.html.erb")
        ).result(b).split("\n").map { |line| ('  ' * depth) + line }.join("\n")
      end

    end
  end
end
