require 'csv'

module Effective
  class CsvImporter
    attr_reader :current_row, :last_row, :csv_file

    A=0;B=1;C=2;D=3;E=4;F=5;G=6;H=7;I=8;J=9;K=10;L=11;M=12;N=13;
    O=14;P=15;Q=16;R=17;S=18;T=19;U=20;V=21;W=22;X=23;Y=24;Z=25;
    AA=26;AB=27;AC=28;AD=29;AE=30;AF=31;AG=32;AH=33;AI=34;AJ=35;
    AK=36;AL=37;AM=38;AN=39;AO=40;AP=41;AQ=42;AR=43;AS=44;AT=45;

    def initialize(csv_file = default_csv_files(), header: true)
      @has_header_row = header

      @csv_file = Array(csv_file).find { |csv_file| File.exists?(csv_file) }
      raise "#{csv_file} does not exist" unless @csv_file
    end

    def columns
      raise "Please define a method 'def columns' returning a Hash of {id: A, name: B}"
    end

    def process_row
      raise "Please define a method 'def process_row' to process your row"
    end

    # Override me if you need some before/after hooks
    def before_import ; end
    def after_import ; end

    # This runs through each row and calls process_row() on it
    def import!
      log "Importing #{csv_file.split('/').last.sub('.csv', '')}"

      @errors_count = 0

      before_import()
      with_each_row { process_row }
      after_import()

      log "Import complete (#{@errors_count} errors in #{@has_header_row ? @current_row_number-1 : @current_row_number} rows)"
    end

    # Returns an Array of Arrays, with each row run through normalize
    def rows
      @rows ||= [].tap do |rows|
        CSV.foreach(csv_file, headers: @has_header_row) do |row|
          rows << columns.map { |column, index| normalize(column, row[index].try(:strip).presence) }
        end
      end
    end

    # UserStudentInfosImporter.new().where(id: 3, title: 'thing')
    # Returns an Array of Hashes, representing any row that matches the selector
    def where(attributes)
      raise 'expected a Hash of attributes' unless attributes.kind_of?(Hash)
      attributes.each { |column, _| raise "unknown column :#{column}" unless columns.key?(column) }

      rows.map do |row|
        if attributes.all? { |column, value| row[columns[column]] == value }
          columns.inject({}) { |retval, (column, index)| retval[column] = row[index]; retval }
        end
      end.compact
    end

    def where!(attributes)
      where(attributes).presence || raise("csv row with #{attributes} not found")
    end

    def find(attributes)
      where(attributes).first
    end

    def find!(attributes)
      find(attributes).presence || raise("csv row with #{attributes} not found")
    end

    # Normalize the value based on column name
    def normalize(column, value)
      column = column.to_s
      value = value.to_s

      if column.ends_with?('?')  # Boolean
        truthy?(value)
      elsif column.ends_with?('_at')  # DateTime
        parse_datetime(column, value)
      elsif column.ends_with?('_on')  # Date
        parse_datetime(column, value).beginning_of_day
      elsif column.ends_with?('_to_i')
        value.to_i
      elsif column.ends_with?('_to_f')
        value.to_f
      elsif column.ends_with?('_to_s')
        value.to_s
      elsif column.ends_with?('_to_a')
        if ['[]', '{}'].include?(value)
          []
        elsif value.starts_with?('{') && value.ends_with?('}')
          YAML::load(value).keys.select { |str| str.to_s.present? }
        else
          YAML::load(value).to_a.select { |str| str.to_s.present? }
        end
      elsif column == 'id' || column.ends_with?('_id')
        value.present? ? value.to_i : nil
      else
        value.presence
      end
    end

    # Takes an object and loops through all columns assigning the current row values
    def assign_columns(obj, only: [], except: [])
      assigns = (
        if only.present?
          only = Array(only)
          columns.keep_if { |key, _| only.include?(key) }
        elsif except.present?
          except = Array(except)
          columns.delete_if { |key, _| except.include?(key) }
        end
      )

      (assigns || columns).each do |column, _|
        obj.send("#{column}=", col(column)) if obj.respond_to?(column)
      end

      obj
    end

    def assign_valid_email(user, at: 'example.com')
      raise 'expected an object that responds to email=' unless user.respond_to?('email=')

      user.email = user.email.to_s.strip.downcase.presence

      if user.email.blank?
        if user.respond_to?(:first_name) && user.respond_to?(:last_name)
          user.email ||= [user.first_name.to_s.parameterize.presence, user.last_name.to_s.parameterize.presence].compact.join('.').presence
        end

        if user.respond_to?(:full_name)
          user.email ||= user.full_name.to_s.parameterize.presence
        end

        if user.respond_to?(:name)
          user.email ||= user.name.to_s.parameterize.presence
        end

        user.email ||= user.object_id

        user.email = "#{user.email}@#{at.sub('@', '')}"
      end

      # Check for uniqueness
      unique = 0
      email = user.email

      while user.class.where(email: email).where.not(id: user.id).present?
        pieces = user.email.split('@')
        email = pieces.first + "+#{(unique += 1)}@" + pieces.last
      end

      user.email = email

      user
    end

    def log(message)
      puts "\n#{message}";
    end

    def error(message)
      @errors_count += 1
      puts "\n#{colorize('Error', :red)} (.csv line #{@current_row_number}) #{message}"
    end

    def warn(message)
      puts "\n#{colorize('Warning', :yellow)} (.csv line #{@current_row_number}) #{message}"
    end

    protected

    def with_each_row(&block)
      @current_row_number = (@has_header_row ? 2 : 1)

      CSV.foreach(csv_file, headers: @has_header_row) do |row|
        @current_row = row

        begin
          exception = false

          ActiveRecord::Base.transaction do
            begin
              yield
            rescue => e
              exception = e
              raise ActiveRecord::Rollback
            end
          end

          raise exception if exception

          print colorize('.', :green)
        rescue => e
          error(e.message)
          puts row
          puts e.backtrace.first(3)
        end

        @current_row_number += 1
        @last_row = row
      end
    end

    def col(column)
      raise "unknown column :#{column} passed to col()" unless columns.key?(column) || column.kind_of?(Integer)

      value = current_row[columns[column] || column].try(:strip).presence

      normalize(column, value)
    end

    def raw_col(column)
      raise "unknown column :#{column} passed to raw_col()" unless columns.key?(column) || column.kind_of?(Integer)
      current_row[columns[column] || column]
    end

    def last_row_col(column)
      raise "unknown column :#{column} passed to last_row_col()" unless columns.key?(column) || column.kind_of?(Integer)

      value = last_row[columns[column] || column].try(:strip).presence

      normalize(column, value)
    end

    def colorize(text, color)
      code = case color
        when :cyan    ; 36
        when :magenta ; 35
        when :blue    ; 34
        when :yellow  ; 33
        when :green   ; 32
        when :red     ; 31
        end

      "\e[#{code}m#{text}\e[0m"
    end

    def parse_first_name(column, value = nil)
      value ||= col(column)
      value.to_s.split(' ')[0]
    end

    def parse_last_name(column, value = nil)
      value ||= col(column)
      value.to_s.split(' ')[1..-1].try(:join, ' ')
    end

    def parse_datetime(column, value = nil)
      value ||= col(column)

      begin
        Time.zone.parse(value.to_s)
      rescue => e
        error("Unable to Time.zone.parse('#{value}'). Override parse_datetime() to parse your own time, something like:\n#{' ' * 6}def parse_datetime(col, value)\n#{' ' * 8}Time.strptime(value, '%m/%d/%Y %H:%M:%S').in_time_zone\n#{' ' * 6}end")
      end
    end

    def truthy?(value)
      if defined?(::ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES)  # Rails <5
        ::ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include?(value)
      else
        ::ActiveRecord::Type::Boolean.new.cast(value)
      end
    end

    private

    def default_csv_files
      [
        ("lib/csv_importers/data/#{self.class.name.gsub('CsvImporters::', '').underscore.gsub('_importer', '')}.csv"),
        ("lib/csv_importers/data/#{self.class.name.gsub('CsvImporters::', '').underscore.gsub('_importer', '').singularize}.csv"),
        ("lib/csv_importers/data/#{self.class.name.gsub('CsvImporters::', '').underscore.gsub('s_importer', '').split('_').map.with_index { |str, index| (index == 0 ? str : str.upcase) }.join}.csv")
      ]
    end

  end
end
