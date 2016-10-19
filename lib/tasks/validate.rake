# bundle exec rake validate
# bundle exec rake validate[user]

desc 'Validates all records of the given ActiveRecord model, defaults to all'
task :validate, [:model] => :environment do |t, args|
  args.with_defaults(:model => 'all')

  Rails.application.eager_load!
  klasses = ActiveRecord::Base.descendants.sort { |a, b| a.name <=> b.name }

  if args.model != 'all'
    klasses.delete_if { |klass| klass.name.downcase != args.model.singularize.downcase }
  end

  klasses.each do |klass|
    invalids = klass.unscoped.order(:id).map do |resource|
      [resource.id, '(' + resource.errors.map { |key, value| "#{key}: #{value}"}.join(', ') + ')'] unless resource.valid?
    end.compact

    if invalids.present?
      puts "#{klass.name}: #{invalids.length} invalid records"
      invalids.each { |invalid| puts invalid.join(' ') }
      puts "Invalid #{klass.name} records: #{invalids.map { |invalid| invalid.first }.join(',')}"
    else
      puts "#{klass.name}: all records valid"
    end
  end


end
