# rails generate effective:menu NAME

# Adds a menu to namespace/_navbar if present
# rails generate effective:menu Thing

module Effective
  module Generators
    class MenuGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Adds a menu link to an existing _navbar.html.haml'

      def invoke_ability
        say_status :invoke, :menu, :white
      end

      def create_menu
        begin
          Effective::CodeWriter.new((['app/views'] + namespaces + ['_navbar.html.haml']).join('/')) do |w|
            index = w.last { |line, _| line.start_with?('- if can?') }

            if index.blank?
              say_status(:skipped, :menu, :yellow) and return
            end

            w.insert_raw(content, index+1, w.depth_at(index))
            say_status :menu, index_path, :green
          end
        rescue Errno::ENOENT
          # This will raise an error if the navbar file isn't present
          say_status :skipped, :menu, :yellow
        end
      end

      private

      def content
        [
          "\n",
          "- if can? :manage, #{class_name}",
          "  %li= link_to '#{plural_name.titleize}', #{index_path}"
        ]
      end
    end
  end
end
