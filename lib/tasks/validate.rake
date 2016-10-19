# bundle exec rake validate
# bundle exec rake validate[user]

desc 'Validates all records of the given ActiveRecord model, defaults to all'
task :validate, [:model] => :environment do |t, args|
  args.with_defaults(:model => 'all')

  Rails.application.eager_load!
  models = ActiveRecord::Base.descendants.sort { |a, b| a.name <=> b.name }

  if args.model != 'all'
    models.delete_if { |model| model.name.downcase != args.model.singularize.downcase }
  end

  models.each do |model|
    invalids = model.unscoped.order(:id).map do |resource|
      [resource.id, '(' + resource.errors.map { |key, value| "#{key}: #{value}"}.join(', ') + ')'] unless resource.valid?
    end.compact

    if invalids.present?
      puts "#{model.name}: #{invalids.length} invalid records"
      invalids.each { |invalid| puts invalid.join(' ') }
      puts "Invalid #{model.name} records: #{invalids.map { |invalid| invalid.first }.join(',')}"
    else
      puts "#{model.name}: all records valid"
    end
  end


end
