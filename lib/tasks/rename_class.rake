# bundle exec rake rename_class[account, team]

desc 'Rename a rails class to another'
task :rename_class, [:source, :target, :db] => :environment do |t, args|
  unless args.source.present? && args.target.present?
    puts 'usage: rake rename_class[account,team] (or rake rename_class[account,team,skipdb] to skip database migrations)' and exit
  end

  source = args.source.to_s.downcase.singularize
  target = args.target.to_s.downcase.singularize

  puts "=== Renaming class '#{source.classify}' to '#{target.classify}'"

  whitelist = ['app/', 'db/', 'lib/', 'test/'].compact
  blacklist = ['db/schema.rb', ('db/migrate' if args.db == 'skipdb')].compact

  # Rename any directories in the app
  Dir.glob('**/*').each do |path|
    next unless whitelist.any? { |ok| path.start_with?(ok) }
    next if blacklist.any? { |nope| path.start_with?(nope) }
    next unless File.directory?(path)

    changed = path.gsub(source.pluralize, target.pluralize).gsub(source, target)

    if path != changed
      File.rename(path, changed)
      puts "renamed: #{path} => #{changed}"
    end
  end

  # For every file in the app
  Dir.glob('**/*.*').each do |path|
    next unless whitelist.any? { |ok| path.start_with?(ok) }
    next if blacklist.any? { |nope| path.start_with?(nope) }

    changed = path.gsub(source.pluralize, target.pluralize).gsub(source, target)

    if path != changed
      File.rename(path, changed)
      puts "renamed: #{path} => #{changed}"
    end
  end

  # For every file in the app
  Dir.glob('**/*.*').each do |path|
    next unless whitelist.any? { |ok| path.start_with?(ok) }
    next if blacklist.any? { |nope| path.start_with?(nope) }

    writer = Effective::CodeWriter.new(path) do |w|
      w.gsub!(source.classify.pluralize, target.classify.pluralize)
      w.gsub!(source.classify, target.classify)
      w.gsub!(source.pluralize, target.pluralize)
      w.gsub!(source, target)
    end

    puts "updated: #{path}" if writer.changed?
  end

end
