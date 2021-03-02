# rails generate effective:menu NAME

# Adds a menu to namespace/_navbar if present
# Adds a menu to namespace/_navbar_admin if present
# rails generate effective:menu Thing

module Effective
  module Generators
    class MenuGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Adds a menu link to an existing _navbar.html.haml'

      def validate_resource
        exit unless resource_valid?
      end

      def invoke_menu
        say_status :invoke, :menu, :white
      end

      # layouts/_navbar.html.haml
      def create_menu
        return unless resource.namespaces.blank?

        begin
          Effective::CodeWriter.new(resource.menu_file) do |w|
            if w.find { |line, _| line == menu_content.second.strip }
              say_status :identical, menu_path, :blue
            else
              if (w.insert_into_first(menu_content) { |line, _| line.include?('.navbar-nav') })
                say_status :menu, menu_path, :green
              else
                say_status(:skipped, :menu, :yellow)
              end
            end
          end
        rescue Errno::ENOENT
          # This will raise an error if the navbar file isn't present
          say_status :skipped, :menu, :yellow
        end
      end

      # layouts/_navbar_admin.html.haml
      def create_admin_menu
        return unless resource.namespaces == ['admin']

        begin
          Effective::CodeWriter.new(resource.admin_menu_file) do |w|
            if w.find { |line, _| line == menu_content.second.strip }
              say_status :identical, menu_path, :blue
            else
              if (w.insert_into_first(menu_content) { |line, _| line.include?('.navbar-nav') })
                say_status :menu, menu_path, :green
              else
                say_status(:skipped, :menu, :yellow)
              end
            end
          end
        rescue Errno::ENOENT
          # This will raise an error if the navbar file isn't present
          say_status :skipped, :menu, :yellow
        end
      end

      private

      def menu_content
        [
          "- if can? :index, #{resource.class_name}",
          "  = nav_link_to '#{resource.plural_name.titleize}', #{menu_path}",
          "\n"
        ]
      end

      def menu_path
        path = [resource.namespace, resource.plural_name, 'path'].compact * '_'
        resource.tenant.present? ? "#{resource.tenant}.#{path}" : path
      end
    end
  end
end
