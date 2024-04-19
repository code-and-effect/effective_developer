namespace :pg do
  # Creates a new backup on remote server, downloads that backup to latest.dump, and then calls pg:load
  #
  # bundle exec rake pg:pull
  # bundle exec rake pg:pull[staging]
  # bundle exec rake pg:pull[158.204.33.124]

  # bundle exec rake pg:pull
  # bundle exec rake pg:pull[staging]
  # bundle exec rake pg:pull[158.204.33.124]
  # bundle exec rake pg:pull logs=true
  # bundle exec rake pg:pull filename=latest.dump database=example
  # bundle exec rake pg:pull filename=latest.dump database=example logs=true
  # DATABASE=example bundle exec rake pg:load
  desc 'Creates a new backup on remote server and downloads it to latest.dump'
  task :pull, [:remote] => :environment do |t, args|
    defaults = { database: nil, filename: (ENV['DATABASE'] || 'latest') + '.dump', logs: 'false' }.compact
    env_keys = { database: ENV['DATABASE'], filename: ENV['FILENAME'], logs: ENV['LOGS'] }.compact
    keywords = ARGV.map { |a| a.split('=') if a.include?('=') }.compact.inject({}) { |h, (k, v)| h[k.to_sym] = v; h }
    args.with_defaults(defaults.merge(env_keys).merge(keywords))

    # Validate Config
    configs = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env)
    config = configs.first

    if configs.length > 1 && args.database.blank?
      puts "Multiple database configs exist for #{Rails.env} environment."
      puts "Please run bundle exec rake pg:pull database=x"
      puts "Where x is one of: #{configs.map { |config| config.name }.to_sentence}"
      exit
    end

    # Heroku mode
    if `git remote -v | grep heroku`.length > 0
      args.with_defaults(remote: 'heroku')

      puts "=== Pulling remote '#{args.remote}' #{args.database} database into #{args.filename}"

      # Create a backup on heroku
      unless system("heroku pg:backups:capture --remote #{args.remote}")
        abort("Error capturing heroku backup")
      end

      # Download it to local
      unless system("curl -o #{args.filename} `heroku pg:backups:public-url --remote #{args.remote}`")
        abort("Error downloading database")
      end

      # Load it
      Rake::Task['pg:load'].invoke(*args)
      exit
    end

    # Hatchbox mode
    if (ENV['HATCHBOX_IP'] || args[:remote]).to_s.count('.') == 3
      args.with_defaults(
        remote: ENV.fetch('HATCHBOX_IP'),
        app: ENV['HATCHBOX_APP'] || `pwd`.split('/').last.chomp,
        user: ENV['HATCHBOX_USER'] || 'deploy'
      )

      puts "=== Pulling hatchbox '#{args.remote}' #{args.app} #{args.database} database into #{args.filename} with#{'out' unless args.logs.to_s == 'true'} logs"

      # SSH into hatchbox and call rake pg:save there to create latest.dump
      unless(result = `ssh -T #{args.user}@#{args.remote} << EOF
        cd ~/#{args.app}/current/
        bundle exec rake pg:save database=#{args.database} filename=#{args.filename} logs=#{args.logs}
      `).include?('Saving database completed') # The output of pg:save down below
        puts("Error calling ssh #{args.user}@#{args.remote} and running rake pg:save on hatchbox from ~/#{args.app}/current/")
        abort(result)
      end

      # SCP to copy the hatchkbox latest.dump to local
      unless system("scp #{args.user}@#{args.remote}:~/#{args.app}/current/#{args.filename} ./")
        abort("Error downloading database")
      end

      # Load it
      Rake::Task['pg:load'].invoke(*args)
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
  # DATABASE=example bundle exec rake pg:load
  desc 'Loads a postgresql .dump file into the development database (latest.dump by default)'
  task :load, [:filename] => :environment do |t, args|
    defaults = { database: nil, filename: (ENV['DATABASE'] || 'latest') + '.dump' }.compact
    env_keys = { database: ENV['DATABASE'], filename: ENV['FILENAME'] }.compact
    keywords = ARGV.map { |a| a.split('=') if a.include?('=') }.compact.inject({}) { |h, (k, v)| h[k.to_sym] = v; h }
    args.with_defaults(defaults.merge(env_keys).merge(keywords))

    # Validate filename
    unless File.exist?(Rails.root + args.filename)
      puts "#{args.filename || none} does not exist"; exit
    end

    # Validate Config
    configs = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env)
    config = configs.first

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

    command = "export PGPASSWORD=#{db[:password]}; pg_restore --no-acl --no-owner --clean --if-exists -h #{db[:host]} -U #{db[:username]} -d #{db[:database]} #{args.filename}"

    if system(command)
      puts "\nLoading database completed"
    else
      abort "\nLoading database completed with errors. It probably worked just fine."
    end
  end

  # bundle exec rake pg:save => Will dump the database to latest.dump
  # bundle exec rake pg:save[something.dump] => Will dump the database to something.dump
  desc 'Saves the development database to a postgresql .dump file (latest.dump by default)'
  task :save, [:filename] => :environment do |t, args|
    defaults = { database: nil, filename: (ENV['DATABASE'] || 'latest') + '.dump', logs: 'false' }.compact
    env_keys = { database: ENV['DATABASE'], filename: ENV['FILENAME'], logs: ENV['LOGS'] }.compact
    keywords = ARGV.map { |a| a.split('=') if a.include?('=') }.compact.inject({}) { |h, (k, v)| h[k.to_sym] = v; h }
    args.with_defaults(defaults.merge(env_keys).merge(keywords))

    db = if ENV['DATABASE_URL'].to_s.length > 0 && args.database.blank?
      uri = URI.parse(ENV['DATABASE_URL']) rescue nil
      abort("Invalid DATABASE_URL") unless uri.present?

      { username: uri.user, password: uri.password, host: uri.host, port: (uri.port || 5432), database: uri.path.sub('/', '') }
    else
      # Validate Config
      configs = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env)
      config = configs.first

      if configs.length > 1 && args.database.blank?
        puts "Multiple database configs exist for #{Rails.env} environment."
        puts "Please run bundle exec rake pg:save database=x"
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

      { username: (config['username'] || `whoami`.chomp), password: config['password'], host: config['host'], port: (config['port'] || 5432), database: config['database'].to_s.sub('/', '') }
    end

    db.transform_values! { |v| v.respond_to?(:chomp) ? v.chomp : v }

    exclude_table_data = "--exclude-table-data=logs --exclude-table-data=*_logs" unless (args.logs.to_s == 'true')

    command = "export PGPASSWORD=#{db[:password]}; pg_dump -Fc --no-acl --no-owner #{exclude_table_data} -h #{db[:host]} -p #{db[:port]} -U #{db[:username]} #{db[:database]} > #{args.filename}"

    puts "=== Saving local '#{db[:database]}' database to #{args.filename} with#{'out' unless args.logs.to_s == 'true'} logs"

    if system(command)
      puts "Saving database completed"
    else
      abort "Error saving database"
    end
  end

  desc 'Clones the production (--remote heroku by default) database to staging (--remote staging by default)'
  task :clone, [:source, :target] => :environment do |t, args|
    args.with_defaults(:source => nil, :target => nil)

    if args.source.blank? || args.target.blank?
      puts 'Need a source and target. Try: bundle exec rake "pg:clone[example,example-staging]"'
      exit
    end

    puts "=== Cloning remote '#{args.source}' to '#{args.target}'"

    Bundler.with_unbundled_env do
      unless system("heroku pg:backups:capture --app #{args.source}")
        abort "Error capturing heroku backup"
      end

      url = (`heroku pg:backups:public-url --app #{args.source}`).chomp

      unless (url || '').length > 0
        abort "Error reading public-url from app #{args.source}"
      end

      unless system("heroku pg:backups:restore '#{url}' DATABASE_URL --app #{args.target}")
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
    db = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first
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
