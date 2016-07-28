# effective_csv_importer 1.0

# Creates one rake task per importer model, as well as a `rake import:all` task.

# Usage:

# Put your importer in /lib/csv_importers/posts.rb
# Put your csv data in /lib/csv_importers/data/posts.csv
# Both filenames should be pluralized

# rake import:posts (one task created per model)
# rake import:all

namespace :import do
  Dir['lib/csv_importers/*.rb'].each do |file|
    importer = file.sub('lib/csv_importers/', '').sub('_importer.rb', '')
    csv_file = "lib/csv_importers/data/#{importer}.csv"
    next unless File.exists?(csv_file)

    # Create a rake task to import this file
    desc "Import #{importer} from #{csv_file}"

    task importer => :environment do
      require "#{Rails.application.root}/#{file}"

      klass = "CsvImporters::#{importer.classify.pluralize}Importer".safe_constantize
      raise "unable to constantize CsvImporters::#{importer.classify.pluralize}Importer for #{file}" unless klass

      klass.new(csv_file).import!
    end
  end
end

# This task is kind of naive, because some imports could be order dependent. Use at your own risk.
namespace :import do
  desc "Import all from /lib/csv_importers/*.rb"

  task :all => :environment do
    Dir['lib/csv_importers/*.rb'].each do |file|
      importer = file.sub('lib/csv_importers/', '').sub('_importer.rb', '')
      csv_file = "lib/csv_importers/data/#{importer}.csv"
      next unless File.exists?(csv_file)

      Rake::Task["import:#{importer}"].invoke
    end
  end

end
