# rails bundle:update_effective_gems
namespace :bundle do
  task :update_effective_gems do
    puts "Updating all effective gems..."

    effective_gems1 = File.readlines('Gemfile').map(&:strip).select { |line| line.start_with?('gem "effective_') }
    effective_gems1 = effective_gems1.map { |line| line.split('"')[1] } # Extract gem name

    effective_gems2 = File.readlines('Gemfile').map(&:strip).select { |line| line.start_with?("gem 'effective_") }
    effective_gems2 = effective_gems2.map { |line| line.split("'")[1] } # Extract gem name

    effective_gems = (effective_gems1 + effective_gems2).sort.uniq

    effective_gems.each do |gem_name|
      puts "Updating #{gem_name}..."
      system("bundle update --conservative #{gem_name}") || abort
    end

    puts "All done updating effective gems"
  end
end
