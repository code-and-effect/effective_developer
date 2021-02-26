namespace :pg do
  # Creates a new backup on remote server, downloads that backup to latest.dump, and then calls pg:load
  #
  # bundle exec rake pg:pull
  # bundle exec rake pg:pull[staging]
  # bundle exec rake pg:pull[158.204.33.124]
  desc 'Creates a new backup on remote server and downloads it to latest.dump'
  task :pull, [:remote] => :environment do |t, args|

    # Heroku mode
    if `git remote -v | grep heroku`.length > 0
      args.with_defaults(remote: 'heroku')

      puts "=== Pulling remote '#{args.remote}' database into latest.dump"

      # Create a backup on heroku
      unless system("heroku pg:backups:capture --remote #{args.remote}")
        abort("Error capturing heroku backup")
      end

      # Download it to local
      unless system("curl -o latest.dump `heroku pg:backups:public-url --remote #{args.remote}`")
        abort("Error downloading database")
      end

      # Load it
      Rake::Task['pg:load'].invoke
      exit
    end

    # Hatchbox mode
    if (ENV['HATCHBOX_IP'] || args[:remote]).count('.') == 3
      args.with_defaults(
        remote: ENV.fetch('HATCHBOX_IP'),
        app: ENV['HATCHBOX_APP'] || `pwd`.split('/').last.chomp,
        user: ENV['HATCHBOX_USER'] || 'deploy'
      )

      puts "=== Pulling hatchbox '#{args.remote}' #{args.app} database into latest.dump"

      # SSH into hatchbox and call rake pg:save there to create latest.dump
      unless(result = `ssh #{args.user}@#{args.remote} << EOF
        cd ~/#{args.app}/current/
        bundle exec rake pg:save[latest.dump]
      `).include?('Saving database completed') # The output of pg:save down below
        puts("Error calling ssh #{args.user}@#{args.remote} and running rake pg:save on hatchbox from ~/#{args.app}/current/")
        abort(result)
      end

      # SCP to copy the hatchkbox latest.dump to local
      unless system("scp #{args.user}@#{args.remote}:~/#{args.app}/current/latest.dump ./")
        abort("Error downloading database")
      end

      # Load it
      Rake::Task['pg:load'].invoke
      exit
    end

    puts "Unable to find pg:pull provider."
    puts "Please add a heroku git remote or a HATCHBOX_IP environment variable and try again"
    abort
  end

  # Drops and re-creates the local database then initializes database with latest.dump
  #
  # bundle exec rake pg:load => Will replace the current database with latest.dump
  # bundle exec rake pg:load[something.dump] => Will replace the current database with something.dump
  # bundle exec rake pg:load filename=latest.dump database=example
  desc 'Loads a postgresql .dump file into the development database (latest.dump by default)'
  task :load, [:filename] => :environment do |t, args|
    defaults = { database: nil, filename: 'latest.dump' }
    env_keys = { database: ENV['DATABASE'], filename: ENV['FILENAME'] }
    keywords = ARGV.map { |a| a.split('=') if a.include?('=') }.compact.inject({}) { |h, (k, v)| h[k.to_sym] = v; h }
    args.with_defaults(defaults.compact.merge(env_keys.compact).merge(keywords))

    # Validate filename
    unless File.exists?(Rails.root + args.filename)
      puts "#{args.filename || none} does not exist"; exit
    end

    # Validate Config
    config = ActiveRecord::Base.configurations[Rails.env]
    configs = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env)

    if configs.length > 1 && args.database.blank?
      puts "Multiple database configs exist for #{Rails.env} environment."
      puts "Please run bundle exec rake pg:load database=x"
      puts "Where x is one of: #{configs.map { |config| config.name }.to_sentence}"
      exit
    end

    if configs.length > 1 && args.database.present?
      config = configs.find { |config| config.name == args.database }
    end

    if config.blank?
      puts "Unable to find Rails database config for #{Rails.env}. Exiting."; exit
    end

    config = config.configuration_hash if config.respond_to?(:configuration_hash)
    config = config.stringify_keys

    db = { username: (config['username'] || `whoami`), password: config['password'], host: config['host'], port: (config['port'] || 5432), database: config['database'] }
    db.transform_values! { |v| v.respond_to?(:chomp) ? v.chomp : v }

    puts "=== Loading #{args.filename} into local '#{db[:database]}' database"

    # bin/rails db:environment:set RAILS_ENV=development
    if Rails.env != 'production'
      ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'
    end

    if configs.length > 1
      Rake::Task["db:drop:#{args.database}"].invoke
      Rake::Task["db:create:#{args.database}"].invoke
    else
      Rake::Task['db:drop'].invoke
      Rake::Task['db:create'].invoke
    end

    if system("export PGPASSWORD=#{db[:password]}; pg_restore --no-acl --no-owner --clean --if-exists -h #{db[:host]} -U #{db[:username]} -d #{db[:database]} #{args.filename}")
      puts "Loading database completed"
    else
      abort "Error loading database"
    end
  end

  # bundle exec rake pg:save => Will dump the database to latest.dump
  # bundle exec rake pg:save[something.dump] => Will dump the database to something.dump
  desc 'Saves the development database to a postgresql .dump file (latest.dump by default)'
  task :save, [:filename] => :environment do |t, args|
    args.with_defaults(:filename => 'latest.dump')

    db = if ENV['DATABASE_URL'].to_s.length > 0
      uri = URI.parse(ENV['DATABASE_URL']) rescue nil
      abort("Invalid DATABASE_URL") unless uri.present?

      { username: uri.user, password: uri.password, host: uri.host, port: (uri.port || 5432), database: uri.path.sub('/', '') }
    else
      config = ActiveRecord::Base.configurations[Rails.env]
      { username: (config['username'] || `whoami`.chomp), password: config['password'], host: config['host'], port: (config['port'] || 5432), database: config['database'] }
    end

    db.transform_values! { |v| v.respond_to?(:chomp) ? v.chomp : v }

    puts "=== Saving local '#{db[:database]}' database to #{args.filename}"

    if system("export PGPASSWORD=#{db[:password]}; pg_dump -Fc --no-acl --no-owner -h #{db[:host]} -p #{db[:port]} -U #{db[:username]} #{db[:database]} > #{args.filename}")
      puts "Saving database completed"
    else
      abort "Error saving database"
    end
  end

  desc 'Clones the production (--remote heroku by default) database to staging (--remote staging by default)'
  task :clone, [:source_remote, :target_remote] => :environment do |t, args|
    args.with_defaults(:source_remote => 'heroku', :target_remote => 'staging')
    db = ActiveRecord::Base.configurations[Rails.env]

    puts "=== Cloning remote '#{args.source_remote}' to '#{args.target_remote}'"

    Bundler.with_clean_env do
      unless system("heroku pg:backups:capture --remote #{args.source_remote}")
        abort "Error capturing heroku backup"
      end

      url = (`heroku pg:backups:public-url --remote #{args.source_remote}`).chomp

      unless (url || '').length > 0
        abort "Error reading public-url from remote #{args.source_remote}"
      end

      unless system("heroku pg:backups:restore '#{url}' DATABASE_URL --remote #{args.target_remote}")
        abort "Error cloning heroku backup"
      end
    end

    puts 'Cloning database complete'
  end

  desc 'Copies a local database table to production (--remote heroku by default) database'
  task :push_table, [:table, :remote] => :environment do |t, args|
    args.with_defaults(:remote => 'heroku')

    if args.table.blank?
      abort "Error, no table name specified. Expected usage: rake pg:push_table[prices]"
    end

    # Find and parse my heroku database info
    regex = Regexp.new(/postgres:\/\/(\w+):(\w+)@(.+):(\d+)\/(\w+)/)
    url = `heroku config --remote #{args.remote} | grep DATABASE_URL`
    info = url.match(regex)

    if info.blank? || info.length != 6
      puts "Unable to find heroku DATABASE_URL"
      puts "Expected \"heroku config --remote #{args.remote} | grep DATABASE_URL\" to be present"
      abort
    end

    heroku = { username: info[1], password: info[2], host: info[3], port: info[4], database: info[5] }

    # Confirm destructive operation
    puts "WARNING: this task will overwrite the #{args.table} database table on #{args.remote}. Proceed? (y/n)"
    abort('Aborted') unless STDIN.gets.chomp.downcase == 'y'

    puts "=== Cloning local table '#{args.table}' to remote #{args.remote} database"

    # Dump my local database table
    db = ActiveRecord::Base.configurations[Rails.env]
    tmpfile = "tmp/#{args.table}.sql"

    unless system("pg_dump --data-only --table=#{args.table} -h localhost -U '#{db['username']}' '#{db['database']}' > #{tmpfile}")
      abort "Error dumping local database table"
    end

    # Now restore it to heroku
    psql = "export PGPASSWORD=#{heroku[:password]}; psql -h #{heroku[:host]} -p #{heroku[:port]} -U #{heroku[:username]} #{heroku[:database]}"
    delete = args.table.split(',').map { |table| "DELETE FROM #{table}" }.join(';')

    unless system("#{psql} -c \"#{delete}\"")
      abort "Error deleting remote table data"
    end

    unless system("#{psql} < #{tmpfile}")
      abort "Error pushing table to remote database"
    end

    # Delete tmpfile
    File.delete(tmpfile)

    # Finished
    puts "Pushing #{args.table} database table complete"
  end

end
