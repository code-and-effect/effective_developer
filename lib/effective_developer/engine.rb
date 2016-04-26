module EffectiveDeveloper
  class Engine < ::Rails::Engine
    engine_name 'effective_developer'

    # Set up our default configuration options.
    initializer 'effective_developer.defaults', before: :load_config_initializers do |app|
      # Set up our defaults, as per our initializer template
      eval File.read("#{config.root}/config/effective_developer.rb")
    end
  end
end
