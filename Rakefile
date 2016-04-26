#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Dir['lib/tasks/**/*.rake'].each { |ext| load ext } if defined?(Rake)
