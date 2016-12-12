# rails generate effective:controller Thing [action action] [options]
# rails generate controller NAME [action action] [options]

module Effective
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      desc "Creates an Effective model in your app/models folder."

      source_root File.expand_path(('../' * 4) + 'app/scaffolds', __FILE__)

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      def create_model
        template 'models/model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      end

      # Used by the migration template to determine the parent name of the model
      def parent_class_name
        options[:parent] || 'ApplicationRecord'
      end

    end
  end
end
