# rails generate effective:view NAME [index show] [options]

module Effective
  module Generators
    class ViewGenerator < Rails::Generators::NamedBase
      include Helpers
      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates one or more views in your app/views folder.'

      argument :actions, type: :array, default: ['crud'], banner: 'index show'
      class_option :attributes, type: :array, default: [], desc: 'Included form attributes, otherwise read from model'

      attr_accessor :attributes

      def assign_attributes
        return if respond_to?(:attributes)

        @attributes = invoked_attributes.map { |attr| Rails::Generators::GeneratedAttribute.parse(attr) }
        self.class.send(:attr_reader, :attributes)
      end

      def create_views
        (invoked_actions & available_actions).each do |action|
          filename = "#{action}.html.haml"

          template "views/#{filename}", File.join('app/views', file_path, filename)
        end
      end

      protected

      def available_actions
        %w(index new show edit)
      end

    end
  end
end
