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

          if writer.find { |line| line.include?('simple_form_for') }
            upgrade_simple_form(writer)
          elsif writer.find { |line| line.include?('semantic_form_for') }
            upgrade_formtastic(writer)
          elsif writer.find { |line| line.include?('form_for') }
            upgrade_form_for(writer)
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

    # simple_form_for [:admin, resource]
    # simple_form_for resource
    SIMPLE_FORM_FOR_REGEX = /simple_form_for( |\()(\[:\w+, ?\w+\])?((\w+),)?.+do \|(\w+)\|/

    def upgrade_simple_form(writer)
      puts "Upgrading simple form: #{writer.filename}"

      # Replace simple_form_for lines
      writer.all { |line| line.include?('simple_form_for') }.each do |line|
        content = writer.lines[line]
        matched = content.match(SIMPLE_FORM_FOR_REGEX)

        original = matched[0]
        model = matched[2] || matched[4]
        letter = matched[5]

        raise("unable to determine simple_form_for subject") unless original && model && letter

        content.gsub!(original, "effective_form_with(model: #{model}) do |#{letter}|")
        writer.replace(line, content)
      end

      # Replace .input
      writer.all { |line| line.include?('.input :') }.each do |line|
        content = writer.lines[line].gsub('.input', '.input_was')
        writer.replace(line, content)
      end

      # .form-actions
      # = f.submit 'Save and Create Another', class: 'btn btn-primary'
      # = f.submit 'Save and Edit Content', class: 'btn btn-primary'
      # = f.submit 'Save', class: 'btn btn-default'
      # = link_to 'Cancel', admin_canadian_tax_planners_path

    end

    def upgrade_formtastic(writer)
      puts "Detected formtastic: #{writer.filename}"
    end

    def upgrade_form_for(writer)
      puts "Detected rails form_for: #{writer.filename}"
    end

    # def upgrade(path)
    #   puts "Annotate: #{path}"

    #   Effective::CodeWriter.new(path) do |writer|
    #     index = find_insert_at(writer)
    #     content = build_content(resource)

    #     remove_existing(writer)
    #     writer.insert(content, index)
    #   end
    # end


  end
end
