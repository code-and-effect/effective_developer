# bundle exec rake sidekiq:start
# bundle exec rake sidekiq:clear

namespace :sidekiq do
  desc 'Starts the sidekiq background job server'
  task :start do
    system('bundle exec sidekiq -C config/sidekiq.yml')
  end

  desc 'Clears all in progress sidekiq jobs'
  task clear: :environment do
    unless Rails.env.development?
      puts "Cannot run in non-development mode"; exit
    end

    require 'sidekiq/api'
    Sidekiq::Queue.all.each { |q| q.clear }

    puts "All sidekiq queues cleared"
  end

end
