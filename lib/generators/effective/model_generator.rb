# rails generate effective:model NAME [field[:type] field[:type]] [options]

# Generates a model
# rails generate effective:model Thing
# rails generate effective:model Thing name:string description:text

module Effective
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a model in your app/models folder.'

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      def create_model
        template 'models/model.rb', File.join('app/models', class_path, "#{singular_name}.rb")
      end

      def to_s_attribute
        attributes.find { |att| ['display_name', 'name', 'title', 'subject'].include?(att.name) }
      end

      def archived_attribute
        attributes.find { |att| att.name == 'archived' && att.type == :boolean }
      end

    end
  end
end
