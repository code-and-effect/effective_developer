require 'csv'

module Effective
  class CSVImporter
    attr_reader :current_row, :last_row

    A=0;B=1;C=2;D=3;E=4;F=5;G=6;H=7;I=8;J=9;K=10;L=11;M=12;N=13;
    O=14;P=15;Q=16;R=17;S=18;T=19;U=20;V=21;W=22;X=23;Y=24;Z=25;
    AA=26;AB=27;AC=28;AD=29;AE=30;AF=31;AG=32;AH=33;AI=34;AJ=35;
    AK=36;AL=37;AM=38;AN=39;AO=40;AP=41;AQ=42;AR=43;AS=44;AT=45;

    def initialize(csv_file, has_header_row = true)
      @csv_file = csv_file.to_s
      @has_header_row = has_header_row
    end

    def csv_file
      @csv_file
    end

    def import!
      log "Importing #{csv_file.split('/').last.sub('.csv', '')}"

      @errors_count = 0

      before_import()
      with_each_row { process_row }
      after_import()

      log "Import complete (#{@errors_count} errors in #{@has_header_row ? @current_row_number-1 : @current_row_number} rows)"
    end

    def with_each_row(&block)
      @current_row_number = (@has_header_row ? 2 : 1)

      CSV.foreach(csv_file, headers: @has_header_row) do |row|
        @current_row = row

        begin
          yield
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

    def columns
      raise "Please define a method 'def columns' returning a Hash of {id: A, name: B}"
    end

    def process_row
      raise "Please define a method 'def process_row' to process your row"
    end

    # Override me if you need some before/after hooks
    def before_import ; end
    def after_import ; end

    # Normalize the value based on column name
    def normalize(column, value)
      column = column.to_s
      value = value.to_s

      if column.ends_with?('?')  # Boolean
        ::ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include?(value)
      elsif column.ends_with?('_at')  # DateTime
        Time.zone.parse(value) rescue nil
      elsif column.ends_with?('_on')  # Date
        Time.zone.parse(value).beginning_of_day rescue nil
      else
        value.presence
      end
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

  end
end
