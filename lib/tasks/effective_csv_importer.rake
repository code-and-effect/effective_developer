# effective_csv_importer 1.0

# Creates one rake task per importer model, as well as a `rake import:all` task.

# Usage:

# Put your importer in /lib/importers/posts.rb
# Put your csv data in /lib/importers/data/posts.csv
# Both filenames should be pluralized

# rake import:posts (one task created per model)
# rake import:all

namespace :import do
  Dir['lib/importers/*.rb'].each do |file|
    importer = file.sub('lib/importers/', '').sub('_importer.rb', '')
    csv_file = "lib/importers/data/#{importer}.csv"

    # Create a rake task to import this file
    desc "Import #{importer} data from #{csv_file}"

    task importer => :environment do
      klass = "Importers::#{importer.classify.pluralize}Importer".safe_constantize
      raise "unable to constantize importer for #{file}" unless klass

      klass.new(csv_file).import!
    end
  end
end

# This task is kind of naive, because some imports could be order dependent. Use at your own risk.
namespace :import do
  desc "Import all data based on /lib/importers/*.rb"

  task :all => :environment do
    Dir['lib/importers/*.rb'].each do |file|
      importer = file.sub('lib/importers/', '').sub('_importer.rb', '')
      csv_file = "lib/importers/data/#{importer}.csv"

      Rake::Task["import:#{importer}"].invoke
    end
  end

end
