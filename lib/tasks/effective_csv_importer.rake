# effective_csv_importer 1.0

# Creates one rake task per importer model, as well as a `rake csv:import:all` task.

# Usage:

# Put your importer in /lib/csv_importers/posts.rb
# Put your csv data in /lib/csv_importers/data/posts.csv
# Both filenames should be pluralized

# rake csv:import:posts (one task created per model)
# rake csv:import:all
# rake csv:scaffold
# rake csv:scaffold[users]
# rake csv:export

namespace :csv do
  namespace :import do
    # Create a rake task to import each csv file
    Dir['lib/csv_importers/*.rb'].each do |file|
      importer = file.sub('lib/csv_importers/', '').sub('_importer.rb', '')
      csv_file = "lib/csv_importers/data/#{importer}.csv"
      next unless File.exists?(csv_file)

      # rake csv:import:foo
      desc "Import #{importer} from #{csv_file}"

      task importer => :environment do
        require "#{Rails.application.root}/#{file}"

        klass = "CsvImporters::#{importer.classify.pluralize}Importer".safe_constantize
        raise "unable to constantize CsvImporters::#{importer.classify.pluralize}Importer for #{file}" unless klass

        klass.new().import!
      end
    end

    # rake csv:import:all
    desc 'Import all from /lib/csv_importers/*.rb'

    task :all => :environment do
      Dir['lib/csv_importers/*.rb'].each do |file|
        importer = file.sub('lib/csv_importers/', '').sub('_importer.rb', '')
        csv_file = "lib/csv_importers/data/#{importer}.csv"
        next unless File.exists?(csv_file)

        Rake::Task["csv:import:#{importer}"].invoke
      end
    end
  end

  # rake csv:scaffold
  # rake csv:scaffold[users]
  desc 'Scaffold an Effective::CSVImporter for each /lib/csv_importers/data/*.csv file, defaults to all'

  task :scaffold, [:file_name] => :environment do |t, args|
    args.with_defaults(file_name: 'all')

    require 'csv'

    generator = ERB.new(File.read(File.dirname(__FILE__) + '/../scaffolds/importers/csv_importer.rb'))
    letters = ('A'..'AT').to_a

    Dir['lib/csv_importers/data/*.csv'].each do |file|
      csv_file = file.split('/').last.gsub('.csv', '')

      next if (Array(args.file_name) != ['all'] && Array(args.file_name).include?(csv_file) == false)
      next if args.file_name == 'all' && File.exists?("#{Rails.root}/lib/csv_importers/#{csv_file}_importer.rb")

      klass = csv_file.classify.pluralize
      columns = CSV.open(file, 'r') { |csv| csv.first }

      File.open("#{Rails.root}/lib/csv_importers/#{csv_file}_importer.rb", 'w') do |file|
        file.write generator.result(binding)
        puts "created lib/csv_importers/#{csv_file}_importer.rb"
      end
    end
  end

  # rake csv:export
  desc 'Export all database tables to /tmp/csv_exports/*.csv'

  task :export => :environment do
    require 'csv'

    path = Rails.root.to_s + '/tmp/csv_exports/'
    FileUtils.mkdir_p(path) unless File.directory?(path)

    (ActiveRecord::Base.connection.tables - ['schema_migrations', 'ar_internal_metadata']).each do |table|
      records = ActiveRecord::Base.connection.exec_query("SELECT * FROM #{table} ORDER BY id")

      CSV.open(path + "#{table}.csv", 'wb') do |csv|
        csv << records.columns
        records.rows.each { |row| csv << row }
      end
    end

    puts "Successfully csv exported #{ActiveRecord::Base.connection.tables.length} tables to #{path}"
  end

end
