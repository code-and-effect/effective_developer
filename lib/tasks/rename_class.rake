# bundle exec rake rename_class[account, team]

desc 'Rename a rails class to another'
task :rename_class, [:source, :target, :db] => :environment do |t, args|
  unless args.source.present? && args.target.present?
    puts 'usage: rake rename_class[account,team] (or rake rename_class[account,team,skipdb] to skip database migrations)' and exit
  end

  source = args.source.to_s.downcase.singularize
  target = args.target.to_s.downcase.singularize

  puts "=== Renaming class '#{source.classify}' to '#{target.classify}'"

  whitelist = ['app/', 'config/routes.rb', 'config/locales/', 'db/', 'lib/', 'test/'].compact
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

  # Rename any files in the app
  Dir.glob('**/*.*').each do |path|
    next unless whitelist.any? { |ok| path.start_with?(ok) }
    next if blacklist.any? { |nope| path.start_with?(nope) }

    changed = path.gsub(source.pluralize, target.pluralize).gsub(source, target)

    if path != changed
      File.rename(path, changed)
      puts "renamed: #{path} => #{changed}"
    end
  end

  # Search and replace in all files
  subs = {
    source.classify.pluralize => target.classify.pluralize,
    source.classify => target.classify,
    source.pluralize => target.pluralize,
    source => target
  }

  if source.include?('_')
    subs[source.gsub('_', '-')] ||= target
  end

  Dir.glob('**/*.*').each do |path|
    next unless whitelist.any? { |ok| path.start_with?(ok) }
    next if blacklist.any? { |nope| path.start_with?(nope) }

    writer = Effective::CodeWriter.new(path) do |w|
      subs.each { |k, v| w.gsub!(k, v) }
    end

    puts "updated: #{path}" if writer.changed?
  end

end
