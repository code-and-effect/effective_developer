# bundle exec rake annotate
# bundle exec rake annotate[user]

desc 'Adds an effective_resources do .. end block to all ActiveRecord model files'
task :annotate, [:resource] => :environment do |t, args|
  args.with_defaults(resource: 'all')
  Effective::Annotator.new(resource: args.resource).annotate!
end
