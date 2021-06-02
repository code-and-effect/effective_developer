# bundle exec rake upgrade_forms
# bundle exec rake upgrade_forms[app/views/admin/]

desc 'Upgrades simple_form_for to effective_form_with'
task :upgrade_forms, [:folder] => :environment do |t, args|

  #args.with_defaults(folder: 'app/views/')
  args.with_defaults(folder: 'app/views/admin/canadian_tax_planners/')
  Effective::FormUpgrader.new(folder: args.folder).upgrade!
end
