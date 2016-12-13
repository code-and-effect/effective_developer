namespace :pg do
  # Creates a new backup on heroku, downloads that backup to latest.dump, and then calls pg:load
  #
  # bundle exec rake pg:pull
  # bundle exec rake pg:pull[staging]
  desc 'Pulls a newly captured backup from heroku (--remote heroku by default) and calls pg:load'
  task :pull, [:remote] => :environment do |t, args|
    args.with_defaults(:remote => 'heroku')

    puts "=== Pulling remote '#{args.remote}' database into latest.dump"

    Bundler.with_clean_env do
      unless system("heroku pg:backups:capture --remote #{args.remote}")
        puts "Error capturing heroku backup"
        exit
      end

      if system("curl -o latest.dump `heroku pg:backups:public-url --remote #{args.remote}`")
        puts "Downloading database completed"
      else
        puts "Error downloading database"
        exit
      end
    end

    Rake::Task['pg:load'].invoke
  end

  # Drops and re-creates the local database then initializes database with latest.dump
  #
  # bundle exec rake pg:load => Will replace the current database with latest.dump
  # bundle exec rake pg:load[something.dump] => Will replace the current database with something.dump
  desc 'Loads a postgresql .dump file into the development database (latest.dump by default)'
  task :load, [:file_name] => :environment do |t, args|
    args.with_defaults(:file_name => 'latest.dump')
    db = ActiveRecord::Base.configurations[Rails.env]

    puts "=== Loading #{args.file_name} into local '#{db['database']}' database"

    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke

    if system("pg_restore --no-acl --no-owner -h localhost -U #{db['username']} -d #{db['database']} #{args.file_name}")
      puts "Loading database completed"
    else
      puts "Error loading database"
    end
  end

  # bundle exec rake pg:save => Will dump the database to latest.dump
  # bundle exec rake pg:save[something.dump] => Will dump the database to something.dump
  desc 'Saves the development database to a postgresql .dump file (latest.dump by default)'
  task :save, [:file_name] => :environment do |t, args|
    args.with_defaults(:file_name => 'latest.dump')
    db = ActiveRecord::Base.configurations[Rails.env]

    puts "=== Saving local '#{db['database']}' database to #{args.file_name}"

    if system("pg_dump -Fc --no-acl --no-owner -h localhost -U '#{db['username']}' '#{db['database']}' > #{args.file_name}")
      puts "Saving database completed"
    else
      puts "Error saving database"
    end
  end

  desc 'Clones the production (--remote heroku by default) database to staging (--remote staging by default)'
  task :clone, [:source_remote, :target_remote] => :environment do |t, args|
    args.with_defaults(:source_remote => 'heroku', :target_remote => 'staging')
    db = ActiveRecord::Base.configurations[Rails.env]

    puts "=== Cloning remote '#{args.source_remote}' to '#{args.target_remote}'"

    Bundler.with_clean_env do
      unless system("heroku pg:backups:capture --remote #{args.source_remote}")
        puts "Error capturing heroku backup"
        exit
      end

      url = (`heroku pg:backups:public-url --remote #{args.source_remote}`).chomp

      unless (url || '').length > 0
        puts "Error reading public-url from remote #{args.source_remote}"
        exit
      end

      unless system("heroku pg:backups:restore '#{url}' DATABASE_URL --remote #{args.target_remote}")
        puts "Error cloning heroku backup"
        exit
      end
    end

    puts 'Cloning database complete'
  end

end
