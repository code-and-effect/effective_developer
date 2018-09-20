module EffectiveDeveloper
  class Engine < ::Rails::Engine
    engine_name 'effective_developer'

    # Set up our default configuration options.
    initializer 'effective_developer.defaults', before: :load_config_initializers do |app|
      # Set up our defaults, as per our initializer template
      eval File.read("#{config.root}/config/effective_developer.rb")
    end

    # Whenever the effective_resource do block is evaluated, check for changes
    initializer 'effective_developer.effective_resources' do |app|
      ActiveSupport.on_load :effective_resource do
        Effective::ResourceMigrator.new(self).migrate! if EffectiveDeveloper.live
      end
    end

  end
end
