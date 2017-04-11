# rails generate effective:datatable NAME [field[:type] field[:type]] [options]

# TODO

# Generates a datatable
# rails generate effective:datatable Thing
# rails generate effective:controller Thing name:string description:text

module Effective
  module Generators
    class DatatableGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates an Effective::Datatable in your app/datatables folder.'

      argument :actions, type: :array, default: ['crud'], banner: 'action action'
      class_option :attributes, type: :array, default: [], desc: 'Included permitted params, otherwise read from model'

      def assign_attributes
        @attributes = invoked_attributes.presence || resource_attributes(all: true)
        self.class.send(:attr_reader, :attributes)
      end

      def invoke_datatable
        say_status :invoke, :datatable, :white
      end

      def create_datatable
        unless defined?(EffectiveDatatables)
          say_status(:skipped, :datatable, :yellow) and return
        end

        template 'datatables/datatable.rb', resource.datatable_file
      end

    end
  end
end
