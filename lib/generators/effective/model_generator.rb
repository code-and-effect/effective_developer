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

      def invoke_model
        say_status :invoke, :model, :white
      end

      def create_model
        template 'models/model.rb', resource.model_file
      end

      protected

      def parent_class_name
        options[:parent] || (Rails::VERSION::MAJOR > 4 ? 'ApplicationRecord' : 'ActiveRecord::Base')
      end

      def to_s_attribute
        [:display_name, :name, :title, :subject].find { |att| invoked_attributes.key?(att) }
      end

      def max_attribute_name_length
        @max_attribute_name_length ||= (invoked_attributes.keys.map { |att| att.to_s.length }.max || 0)
      end

    end
  end
end
