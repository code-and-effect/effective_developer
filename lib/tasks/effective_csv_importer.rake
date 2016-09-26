# effective_csv_importer 1.0

# Creates one rake task per importer model, as well as a `rake csv:import:all` task.

# Usage:

# Put your importer in /lib/csv_importers/posts.rb
# Put your csv data in /lib/csv_importers/data/posts.csv
# Both filenames should be pluralized

# rake csv:import:posts (one task created per model)
# rake csv:import:all

namespace :csv do
  namespace :import do
    Dir['lib/csv_importers/*.rb'].each do |file|
      importer = file.sub('lib/csv_importers/', '').sub('_importer.rb', '')
      csv_file = "lib/csv_importers/data/#{importer}.csv"
      next unless File.exists?(csv_file)

      # rake csv:import:foo - Create a rake task to import this file
      desc "Import #{importer} from #{csv_file}"

      task importer => :environment do
        require "#{Rails.application.root}/#{file}"

        klass = "CsvImporters::#{importer.classify.pluralize}Importer".safe_constantize
        raise "unable to constantize CsvImporters::#{importer.classify.pluralize}Importer for #{file}" unless klass

        klass.new(csv_file).import!
      end
    end

    # rake csv:import:all - Run all importers in alphabetical order (kind of naive)
    desc 'Import all from /lib/csv_importers/*.rb'

    task :all => :environment do
      Dir['lib/csv_importers/*.rb'].each do |file|
        importer = file.sub('lib/csv_importers/', '').sub('_importer.rb', '')
        csv_file = "lib/csv_importers/data/#{importer}.csv"
        next unless File.exists?(csv_file)

        Rake::Task["csv:import:#{importer}"].invoke
      end
    end

    # rake csv:scaffold - Creates a placeholder importer for each /lib/csv_importers/data/*.csv file
    desc 'Scaffold a Effective::CSVImporter for each /lib/csv_importers/data/*.csv file'

    task :scaffold => :environment do
      require 'csv'

      generator = ERB.new(File.read(File.dirname(__FILE__) + '/../generators/effective_developer/csv_importer.rb.erb'))

      Dir['lib/csv_importers/data/*.csv'].each do |file|
        csv_file = file.split('/').last.gsub('.csv', '')

        klass = csv_file.classify.pluralize
        columns = CSV.open(file, 'r') { |csv| csv.first }

        File.open("#{Rails.root}/lib/csv_importers/#{csv_file}_importer.rb", 'w') do |file|
          file.write generator.result(binding)
        end
      end
    end

  end

  # rake csv:export
  desc 'Export all database tables to /tmp/csv_exports/*.csv'

  task :export => :environment do
    require 'csv'

    path = Rails.root.to_s + '/tmp/csv_exports/'
    FileUtils.mkdir_p(path) unless File.directory?(path)

    (ActiveRecord::Base.connection.tables - ['schema_migrations']).each do |table|
      records = ActiveRecord::Base.connection.exec_query("SELECT * FROM #{table}")

      CSV.open(path + "#{table}.csv", 'wb') do |csv|
        csv << records.columns
        records.rows.each { |row| csv << row }
      end
    end

    puts "Successfully csv exported #{ActiveRecord::Base.connection.tables.length} tables to #{path}"
  end

end
