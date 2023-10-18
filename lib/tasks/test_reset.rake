# bundle exec rake app:test:reset
namespace :test do
  desc 'Resets a gem test schema to a clean slate'
  task reset: :environment do
    unless Rails.env.development?
      puts "Cannot run in non-development mode"; exit
    end

    unless File.exist?('Gemfile')
      puts 'Unable to proceed, Gemfile must be present in current directory'
      puts "Please run rake app:test:reset from the gem's root directory"
      exit
    end

    # Delete schema
    File.delete('test/dummy/db/schema.rb') if File.exist?('test/dummy/db/schema.rb')

    # Run rake db:reset
    system('rake db:drop db:create db:migrate db:seed')

    puts "All Done. Test schema has been reset"
  end

end
