# rails generate effective:route NAME [action action] [options]

# TODO - support actions

# Adds a route to config/routes.rb
# rails generate effective:route Thing
# rails generate effective:model Thing index edit create

module Effective
  module Generators
    class RouteGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a route.'

      argument :actions, type: :array, default: ['crud'], banner: 'action action'

      def create_route
        lines = File.open('config/routes.rb').readlines

        # Find and replace resources
        if namespaces.blank?
          index = index_with_depth(lines) { |line, depth| depth == 1 && line.strip.start_with?("resources :#{plural_name}") }

          if index.blank?
            index = index_with_depth(lines) { |line, depth| depth == 1 && line.strip.start_with?('resources') }
            index = index + 1 if index

            index ||= indexes_with_depth(lines) { |line, depth| depth == 1 && line.strip.start_with?('namespace') }.first
            index ||= indexes_with_depth(lines) { |line, depth| depth == 1 && line.strip.start_with?('root') }.last
            index ||= indexes_with_depth(lines) { |line, depth| depth == 1 && line.strip == 'end' }.last

            insert(lines, index, resources)
          end
        end

        File.open('config/routes.rb', 'w') do |file|
          lines.each { |line| file.write(line) }
        end

        #binding.pry
        #Rails::Generators.invoke('resource_route', [[namespace_path.presence, plural_name].compact.join('/')])
      end

      private

      def namespaces
        namespace_path.split('/').map { |namespace| "namespace :#{namespace} do"}
      end

      def resources
        @resources ||= (
          resources = [
            "resources :#{plural_name}",
            (", only: [#{(crud_actions & invoked_actions).map { |action| ':' + action.to_s}.join(', ')}]" if (crud_actions - invoked_actions).present?)
          ].compact.join

          if (crud_actions - invoked_actions).present?
            resources << " do\n" << (crud_actions - invoked_actions).map { |action| "\tget :#{action}, on: :member" }.join("\n") << "\nend"
          end

          resources
        )
      end

      def insert(lines, index, string)
        whitespace = ''

        index.downto(0) do |i|
          if lines[i] =~ /\S/
            whitespace = lines[i][0...lines[i].index(/\S/)]
            break
          end
        end

        inserts = string.split("\n")

        # If there is an empty line above our insert point, keep that empty line
        if index > 0 && lines[index-1] !=~ /\S/
          index = index - 1
        end

        inserts.reverse.each do |line|
          if line == "\n"
            lines.insert(index, line)
          else
            lines.insert(index, whitespace + line + "\n")
          end
        end

        # If the command right above me is not the same, add another line
        if index > 0 && lines[index-1].include?(' do') == false
          command = inserts.first[0...inserts.first.index(/\s/)]
          prev_command = lines[index-1][0...lines[index-1].index(/\s/)]

          lines.insert(index, "\n") unless prev_command.start_with?(command) && inserts.length == 1
        end
      end

    end
  end
end
