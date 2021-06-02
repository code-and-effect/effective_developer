# Upgrades simple_form_for to effective_form_with
module Effective
  class FormUpgrader

    def initialize(folder: 'app/views/')
      @folders = Array(folder)
    end

    def upgrade!
      @folders.each do |folder|
        Dir.glob(folder + '**/*').each do |path|
          next if File.directory?(path)
          next unless path.include?('.html')

          writer = Effective::CodeWriter.new(path)

          name = path.split('/')[0...-1] - ['app', 'views']
          resource = Effective::Resource.new(name)

          if writer.find { |line| line.include?('simple_form_for') }
            upgrade_simple_form(writer, resource)
          elsif writer.find { |line| line.include?('semantic_form_for') }
            upgrade_formtastic(writer, resource)
          elsif writer.find { |line| line.include?('form_for') }
            upgrade_form_for(writer, resource)
          else
            next # Nothign to do
          end

          writer.write!
        end
      end

      puts 'All Done. Have a great day.'
      true
    end

    private

    SIMPLE_FORM_FOR_REGEX = /simple_form_for( |\()(\[:\w+, ?\w+\])?((\w+),)?.+do \|(\w+)\|/
    SIMPLE_FORM_INPUT_ATTRIBUTE = /\.input( |\():(\w+),?/
    SIMPLE_FORM_INPUT_AS_ONE = /(as: :(\w+))/
    SIMPLE_FORM_INPUT_AS_TWO = /(:as => :(\w+))/

    def upgrade_simple_form(writer, resource)
      puts "Upgrading simple form: #{writer.filename}"

      # Replace simple_form_for
      writer.all { |line| line.include?('simple_form_for') }.each do |line|
        content = writer.lines[line]
        matched = content.match(SIMPLE_FORM_FOR_REGEX)
        raise("unable to match simple_form_for from:\n#{content}") unless matched.present?

        original = matched[0]
        model = matched[2] || matched[4]
        letter = matched[5]

        raise("unable to determine simple_form_for subject from:\n#{content}") unless original && model && letter

        content.sub!(original, "effective_form_with(model: #{model}) do |#{letter}|")
        writer.replace(line, content)
      end

      # Replace .input
      writer.all { |line| line.include?('.input :') }.each do |line|
        content = writer.lines[line]
        attribute = content.match(SIMPLE_FORM_INPUT_ATTRIBUTE)
        raise("unable to match simple_form_for input attribute from\n#{content}") unless attribute.present?

        as = content.match(SIMPLE_FORM_INPUT_AS_ONE) || content.match(SIMPLE_FORM_INPUT_AS_TWO)

        if as.present?
          content.sub!("#{as[0]}, ", '')
          content.sub!("#{as[0]},", '')
          content.sub!(as[0], '')
        end

        input_type = find_input_type(resource: resource, attribute: attribute[2], as: (as[2] if as))

        content.sub!('input', input_type)
        writer.replace(line, content)
      end

      # .form-actions
      # = f.submit 'Save and Create Another', class: 'btn btn-primary'
      # = f.submit 'Save and Edit Content', class: 'btn btn-primary'
      # = f.submit 'Save', class: 'btn btn-default'
      # = link_to 'Cancel', admin_canadian_tax_planners_path

    end

    def upgrade_formtastic(writer, resource)
      puts "Detected formtastic: #{writer.filename}"
    end

    def upgrade_form_for(writer, resource)
      puts "Detected rails form_for: #{writer.filename}"
    end

    def find_input_type(attribute:, resource:, as: nil)
      input_type = (as || resource.sql_type(attribute)).to_s

      case input_type
      when 'effective_date_picker' then 'date_field'
      when 'select', 'effective_select' then 'select'
      when 'boolean' then 'check_box'
      when 'text' then 'text_area'
      when 'string' then 'text_field'
      when 'integer' then 'number_field'
      else
        raise("unknown input type for #{attribute} of type #{input_type}")
      end
    end

  end
end
