# rails bundle:update_effective_gems
namespace :bundle do
  task :update_effective_gems do
    puts "Updating all effective gems..."

    effective_gems = File.readlines('Gemfile').map(&:strip).select { |line| line.start_with?('gem "effective_') }
    effective_gems = effective_gems.map { |line| line.split('"')[1] } # Extract gem name

    effective_gems.each do |gem_name|
      puts "Updating #{gem_name}..."
      system("bundle update --conservative #{gem_name}") || abort
    end

    puts "All done updating effective gems"
  end
end
