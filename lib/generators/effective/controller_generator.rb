# rails generate effective:controller Thing [action action] [options]
# rails generate controller NAME [action action] [options]

module Effective
  module Generators
    class ControllerGenerator < Rails::Generators::NamedBase
      desc "Creates an Effective controller in your app/controllers folder."

      source_root File.expand_path(('../' * 4) + 'app/scaffolds', __FILE__)

      argument :actions, type: :array, default: ['crud'], banner: 'index show'

      def parse_actions
        if @actions == ['crud']
          @actions = %w(index new create show edit update destroy)
        else
          @actions = Array(@actions).flat_map { |arg| arg.gsub('[', '').gsub(']', '').split(',') }
        end
      end

      def create_controller
        puts "Create controller"
        template 'controllers/controller.rb', "app/controllers/#{file_name}_controller.rb"
      end
    end
  end
end
