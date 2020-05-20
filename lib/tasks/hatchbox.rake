namespace :hatchbox do
  namespace :pg do
    # Creates a new backup on heroku, downloads that backup to latest.dump, and then calls pg:load
    #
    # bundle exec rake heroku:pull
    # bundle exec rake heroku:pull[staging]
    desc 'Pulls a newly captured backup from heroku (--remote heroku by default) and calls pg:load'
    task :pull, [:remote] => :environment do |t, args|
      args.with_defaults(remote: ENV['HATCHBOX_IP'])

      puts "=== Pulling remote '#{args.remote}' database into latest.dump"

      #scp deploy@159.203.32.114:~/cab/current/latest.dump ./
    end

  end
end
