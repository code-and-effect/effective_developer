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

      def invoke_menu
        say_status :invoke, :menu, :white
      end

      # layouts/_navbar.html.haml
      def create_menu
        return unless resource.namespaces.blank?

        begin
          Effective::CodeWriter.new('app/views/layouts/_navbar.html.haml') do |w|
            if w.find { |line, _| line == menu_content.last.strip }
              say_status :identical, menu_path, :blue
            else
              if (w.insert_after_first(menu_content) { |line, _| line.start_with?('= nav_link_to') })
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
          Effective::CodeWriter.new('app/views/layouts/_navbar_admin.html.haml') do |w|
            if w.find { |line, _| line == admin_menu_content.last.strip }
              say_status :identical, menu_path, :blue
            else
              index = w.last { |line, _| line.start_with?('- if can?') }

              if index.blank?
                say_status(:skipped, :menu, :yellow) and return
              end

              w.insert_raw(admin_menu_content, index+1, w.depth_at(index))
              say_status(:menu, menu_path, :green)
            end
          end
        rescue Errno::ENOENT
          # This will raise an error if the navbar file isn't present
          say_status :skipped, :menu, :yellow
        end
      end

      private

      def menu_content
        ["= nav_link_to '#{resource.plural_name.titleize}', #{menu_path}"]
      end

      def admin_menu_content
        [
          "\n",
          "- if can? :manage, #{resource.class_name}",
          "  = nav_link_to '#{resource.plural_name.titleize}', #{menu_path}"
        ]
      end

      def menu_path
        [resource.namespace, resource.plural_name, 'path'].compact * '_'
      end
    end
  end
end
