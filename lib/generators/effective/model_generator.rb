# rails generate effective:model NAME [field[:type] field[:type]] [options]

module Effective
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'app/scaffolds', __FILE__)

      desc 'Creates a model in your app/models folder.'

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      def create_model
        template 'models/model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      end

    end
  end
end
