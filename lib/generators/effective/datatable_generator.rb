# rails generate effective:datatable NAME [field[:type] field[:type]] [options]

module Effective
  module Generators
    class DatatableGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'app/scaffolds', __FILE__)

      desc 'Creates an Effective::Datatable in your app/effective/datatables folder.'

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      def create_datatable
        template 'datatables/datatable.rb', File.join('app/models/effective/datatables', class_path, "#{file_name}.rb")
      end

    end
  end
end
