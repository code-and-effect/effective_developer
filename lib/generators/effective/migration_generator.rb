# rails generate effective:migration NAME [field[:type] field[:type]] [options]

# TODO - add default options

# Generates a create_* migration
# rails generate effective:migration Thing
# rails generate effective:migration Thing name:string description:text

module Effective
  module Generators
    class MigrationGenerator < Rails::Generators::NamedBase
      include Helpers

      source_root File.expand_path(('../' * 4) + 'lib/scaffolds', __FILE__)

      desc 'Creates a migration.'

      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      def invoke_migration
        say_status :invoke, :migration, :white
      end

      def create_migration
        if invoked_attributes.present?
          Rails::Generators.invoke('migration', ["create_#{plural_name}"] + (invoked_attributes | timestamps))
        elsif klass_attributes(verbose: false).present?
          raise 'klass_attributes already exist.  We cant migrate (yet). Exiting.'
        elsif written_attributes.present?
          Rails::Generators.invoke('migration', ["create_#{plural_name}"] + (written_attributes | timestamps))
        else
          raise 'You need to specify some attributes or have a model file present'
        end
      end

      protected

      # Written attributes include all belong_tos, as well as
      # any Attributes comments as per our custom 'Attributes' comment block contained in the model file

      # Attributes
      # name        :string
      # description :text
      #
      # another :string

      def written_attributes
        @written_attributes ||= (
          attributes = []

          Effective::CodeWriter.new(File.join('app/models', class_path, "#{file_name}.rb")) do |w|
            # belong_tos
            references = w.select { |line| line.start_with?('belongs_to '.freeze) }

            if references.present?
              attributes += w.map(indexes: references) { |line| [[line.scan(/belongs_to\s+:(\w+)/).flatten.first, 'references']] }
            end

            # Attributes
            first = w.find { |line| line == '# Attributes' }
            break unless first

            last = w.find(from: first) { |line| line.start_with?('#') == false && line.length > 0 }
            break unless last

            attributes += w.map(from: first+1, to: last-1) { |line| line.scan(/^\W+(\w+)\W+:(\w+)/).presence }
          end

          attributes.flatten(1).compact.map { |attribute| attribute.join(':') }
        )
      end

      def timestamps
        ['created_at:datetime', 'updated_at:datetime']
      end

    end
  end
end
