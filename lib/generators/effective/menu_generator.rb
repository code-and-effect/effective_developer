# rails generate effective:menu NAME

# Adds a menu to namespace/_navbar if present
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

      def create_menu
        begin
          Effective::CodeWriter.new((['app/views'] + resource.namespaces + ['_navbar.html.haml']).join('/')) do |w|
            if w.find { |line, _| line == menu_content.last.strip }
              say_status :identical, resource.index_path, :blue
            else
              index = w.last { |line, _| line.start_with?('- if can?') }

              if index.blank?
                say_status(:skipped, :menu, :yellow) and return
              end

              w.insert_raw(menu_content, index+1, w.depth_at(index))
              say_status :menu, resource.index_path, :green
            end
          end
        rescue Errno::ENOENT
          # This will raise an error if the navbar file isn't present
          say_status :skipped, :menu, :yellow
        end
      end

      def create_effective_menus
        begin
          Effective::CodeWriter.new('lib/tasks/generate/effective_menus.rake') do |w|
            if w.find { |line, _| line == effective_menus_content }
              say_status :identical, resource.index_path, :blue
            else
              index = w.first { |line, _| line.start_with?('item') }

              w.insert(effective_menus_content, index)

              system('rake generate:effective_menus')

              say_status :effective_menus, resource.plural_name + '_path', :green
            end
          end
        rescue Errno::ENOENT
          # This will raise an error if the navbar file isn't present
          say_status :skipped, :effective_menus, :yellow
        end
      end

      private

      def menu_content
        [
          "\n",
          "- if can? :manage, #{resource.class_name}",
          "  %li= link_to '#{resource.plural_name.titleize}', #{resource.index_path}"
        ]
      end

      def effective_menus_content
        "item '#{resource.plural_name.titleize}', :#{resource.plural_name}_path"
      end

    end
  end
end
