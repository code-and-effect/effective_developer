# bundle exec rake replace_assets
desc 'Replaces effective_assets with ActiveStorage'
task :replace_assets => :environment do
  Effective::AssetReplacer.new.replace!
end
