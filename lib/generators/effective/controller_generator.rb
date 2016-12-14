# rails generate effective:controller NAME [action action] [options]

module Effective
  module Generators
    class ControllerGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a controller in your app/controllers folder.'

      argument :actions, type: :array, default: ['crud'], banner: 'action action'
      class_option :attributes, type: :array, default: [], desc: 'Included permitted params, otherwise read from model'

      attr_accessor :attributes

      def initialize(args, *options)
        if options.kind_of?(Array) && options.second.kind_of?(Hash)
          self.attributes = options.second.delete(:attributes)
        end

        super
      end

      def assign_actions
        @actions = invoked_actions
      end

      def create_controller
        template 'controllers/controller.rb', File.join('app/controllers', class_path, "#{plural_name}_controller.rb")
      end

    end
  end
end
