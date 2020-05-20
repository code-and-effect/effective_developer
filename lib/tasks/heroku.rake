namespace :heroku do
  namespace :pg do
    # Creates a new backup on heroku, downloads that backup to latest.dump, and then calls pg:load
    #
    # bundle exec rake heroku:pg:pull
    # bundle exec rake heroku:pg:pull[staging]
    desc 'Pulls a newly captured backup from heroku (--remote heroku by default)'
    task :pull, [:remote] => :environment do |t, args|
      args.with_defaults(remote: 'heroku')

      puts "=== Pulling remote '#{args.remote}' database into latest.dump"

      Bundler.with_clean_env do
        unless system("heroku pg:backups:capture --remote #{args.remote}")
          puts("Error capturing heroku backup")
          exit
        end

        if system("curl -o latest.dump `heroku pg:backups:public-url --remote #{args.remote}`")
          puts "Downloading database completed"
        else
          puts "Error downloading database"
        end
      end
    end

  end
end
