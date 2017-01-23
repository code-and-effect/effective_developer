$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'effective_developer/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'effective_developer'
  s.version     = EffectiveDeveloper::VERSION
  s.authors     = ['Code and Effect']
  s.email       = ['info@codeandeffect.com']
  s.homepage    = 'https://github.com/code-and-effect/effective_developer'
  s.summary     = 'Provides some quality of life developer tools.'
  s.description = 'Provides some quality of life developer tools.'
  s.licenses    = ['MIT']

  s.files = Dir['{app,config,db,lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'rails', '>= 3.2.0'
  s.add_dependency 'effective_resources'

  #s.add_dependency 'haml-rails'
  #s.add_dependency 'sass-rails'
end
