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

    # bin/rails db:environment:set RAILS_ENV=development
    if Rails.env != 'production'
      ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'
    end

    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke

    if system("pg_restore --no-acl --no-owner --clean --if-exists -h localhost -U #{db['username']} -d #{db['database']} #{args.file_name}")
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

  desc 'Copies a local database table to production (--remote heroku by default) database'
  task :push_table, [:table, :remote] => :environment do |t, args|
    args.with_defaults(:remote => 'heroku')

    if args.table.blank?
      puts "Error, no table name specified. Expected usage: rake pg:push_table[prices]"; exit
    end

    # Find and parse my heroku database info
    regex = Regexp.new(/postgres:\/\/(\w+):(\w+)@(.+):(\d+)\/(\w+)/)
    url = `heroku config --remote #{args.remote} | grep DATABASE_URL`
    info = url.match(regex)

    if info.blank? || info.length != 6
      puts "Unable to find heroku DATABASE_URL"
      puts "Expected \"heroku config --remote #{args.remote} | grep DATABASE_URL\" to be present"
      exit
    end

    heroku = { username: info[1], password: info[2], host: info[3], port: info[4], database: info[5] }

    # Confirm destructive operation
    puts "WARNING: this task will overwrite the #{args.table} database table on #{args.remote}. Proceed? (y/n)"
    (puts 'Aborted' and exit) unless STDIN.gets.chomp.downcase == 'y'

    puts "=== Cloning local table '#{args.table}' to remote #{args.remote} database"

    # Dump my local database table
    db = ActiveRecord::Base.configurations[Rails.env]
    tmpfile = "tmp/#{args.table}.sql"

    unless system("pg_dump --data-only --table=#{args.table} -h localhost -U '#{db['username']}' '#{db['database']}' > #{tmpfile}")
      puts "Error dumping local database table"; exit
    end

    # Now restore it to heroku
    psql = "export PGPASSWORD=#{heroku[:password]}; psql -h #{heroku[:host]} -p #{heroku[:port]} -U #{heroku[:username]} #{heroku[:database]}"
    delete = args.table.split(',').map { |table| "DELETE FROM #{table}" }.join(';')

    unless system("#{psql} -c \"#{delete}\"")
      puts "Error deleting remote table data"; exit
    end

    unless system("#{psql} < #{tmpfile}")
      puts "Error pushing table to remote database"; exit
    end

    # Delete tmpfile
    File.delete(tmpfile)

    # Finished
    puts "Pushing #{args.table} database table complete"
  end

end
