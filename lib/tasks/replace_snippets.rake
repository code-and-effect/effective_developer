# bundle exec rake replace_snippets
desc 'Replaces effective_assets snippets with ActiveStorage uploads'
task :replace_snippets => :environment do
  Effective::SnippetReplacer.new.replace!
end
