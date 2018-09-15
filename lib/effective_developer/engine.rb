module EffectiveDeveloper
  class Engine < ::Rails::Engine
    engine_name 'effective_developer'

    # Set up our default configuration options.
    initializer 'effective_developer.defaults', before: :load_config_initializers do |app|
      # Set up our defaults, as per our initializer template
      eval File.read("#{config.root}/config/effective_developer.rb")
    end

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_developer.effective_resources' do |app|
      ActiveSupport.on_load :effective_resource do
        #Effective::Migrator.new(self).migrate!
      end
    end

  end
end
