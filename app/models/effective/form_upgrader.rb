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
            next # Nothing to do
          end

          writer.write!
        end
      end

      puts 'All Done. Have a great day.'
      true
    end

    private

    SIMPLE_FORM_FOR_REGEX = /simple_form_for( |\()(\[:[^,]+, ?[^,]+\])?(([^,]+),)?.+do \|(\w+)\|/
    SIMPLE_FORM_INPUT_ATTRIBUTE = /\.input( |\():(\w+)/
    SIMPLE_FORM_INPUT_AS_ONE = /(as: :(\w+))/
    SIMPLE_FORM_INPUT_AS_TWO = /(:as => :(\w+))/
    SIMPLE_FORM_INPUT_COLLECTION_ONE = /(collection: ([^,]+?))(,|$)/
    SIMPLE_FORM_INPUT_COLLECTION_TWO = /(:collection => :([^,]+?))(,|$)/

    def upgrade_simple_form(writer, resource)
      puts "Upgrading simple form: #{writer.filename}"

      letter = nil
      model = nil

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

      # Try to figure out klass again if its missing from filename
      if resource.klass.blank? && model.present?
        name = model.sub('[', '').sub(']', '').sub(' ', '').split(',').map do |value|
          value.sub('current_', '').sub('@', '').sub(':', '')
        end

        resource = Effective::Resource.new(name)
      end

      if resource.klass.blank? && writer.filename.include?('/devise/')
        resource = Effective::Resource.new('user')
      end

      if resource.klass.blank?
        puts " => Warning: Unable to determine klass of #{model}"
      end

      # Replace .input
      writer.all { |line| line.include?('.input :') }.each do |line|
        content = writer.lines[line]
        attribute = content.match(SIMPLE_FORM_INPUT_ATTRIBUTE)
        raise("unable to match simple_form_for input attribute from\n#{content}") unless attribute.present?

        as = content.match(SIMPLE_FORM_INPUT_AS_ONE) || content.match(SIMPLE_FORM_INPUT_AS_TWO)
        collection = content.match(SIMPLE_FORM_INPUT_COLLECTION_ONE) || content.match(SIMPLE_FORM_INPUT_COLLECTION_TWO)

        if as.present?
          content.sub!(",#{as[0]}", '')
          content.sub!(", #{as[0]}", '')
        end

        if collection.present?
          content.sub!(",#{collection[0]}", ',')
          content.sub!(", #{collection[0]}", ',')
          content.sub!(attribute[0], "#{attribute[0]} #{collection[2]},")
        end

        input_type = find_input_type(resource: resource, attribute: attribute[2], as: (as[2] if as))

        content.sub!('input', input_type)
        writer.replace(line, content)
      end

      # Replace simple_fields_for
      writer.all { |line| line.include?(".simple_fields_for") }.each do |line|
        content = writer.lines[line]

        content.sub!(".simple_fields_for", ".has_many")
        writer.replace(line, content)
      end

      # Replace f.submit
      writer.all { |line| line.include?("#{letter}.submit") }.each do |line|
        content = writer.lines[line]

        content.sub!("#{letter}.submit", "#{letter}.save")
        writer.replace(line, content)
      end

      # Replace f.button :submit
      writer.all { |line| line.include?(".button :submit,") }.each do |line|
        content = writer.lines[line]

        content.sub!(".button :submit,", ".submit")
        writer.replace(line, content)
      end

      # Replace .form-actions
      writer.all { |line| line == '.form-actions' }.each do |line|
        content = writer.lines[line]

        content.sub!('.form-actions', "= #{letter}.submit do")
        writer.replace(line, content)
      end
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
      when 'asset_box_simple_form' then 'file_field'
      when 'belongs_to', 'belongs_to_polymorphic' then 'select'
      when 'boolean' then 'check_box'
      when 'check_boxes' then 'checks'
      when 'date' then 'date_field'
      when 'datetime' then 'datetime_field'
      when 'decimal' then 'float_field'
      when 'effective_ckeditor_text_area' then 'rich_text_area' # I guess
      when 'effective_date_picker' then 'date_field'
      when 'effective_date_time_picker' then 'datetime_field'
      when 'effective_email' then 'email_field'
      when 'effective_price' then 'price_field'
      when 'effective_radio_buttons' then 'radios'
      when 'effective_select' then 'select'
      when 'effective_static_control' then 'static_field'
      when 'effective_tel' then 'phone_field'
      when 'effective_time_picker' then 'time_field'
      when 'effective_url' then 'url_field'
      when 'email' then 'email_field'
      when 'file' then 'file_field'
      when 'hidden' then 'hidden_field'
      when 'integer' then 'number_field'
      when 'number' then 'number_field'
      when 'password' then 'password_field'
      when 'phone' then 'phone_field'
      when 'price' then 'price_field'
      when 'radio_buttons' then 'radios'
      when 'search' then 'search_field'
      when 'select' then 'select'
      when 'static_control' then 'static_field'
      when 'string' then 'text_field'
      when 'tel', 'telephone' then 'phone_field'
      when 'text' then 'text_area'
      when 'url' then 'url_field'
      else
        raise("unknown input type #{input_type} (for attribute :#{attribute})")
      end
    end

  end
end
