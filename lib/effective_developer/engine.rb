module EffectiveDeveloper
  class Engine < ::Rails::Engine
    engine_name 'effective_developer'

    # Set up our default configuration options.
    initializer 'effective_developer.defaults', before: :load_config_initializers do |app|
      # Set up our defaults, as per our initializer template
      eval File.read("#{config.root}/config/effective_developer.rb")
    end

    # Whenever the effective_resource do block is evaluated, check for changes
    # https://stackoverflow.com/questions/13506690/how-to-determine-if-rails-is-running-from-cli-console-or-as-server
    initializer 'effective_developer.effective_resources' do |app|
      if defined?(Rails::Server) && Rails.env.development? && EffectiveDeveloper.live
        ActiveSupport.on_load :effective_resource do
          Effective::LiveGenerator.new(self).generate!
        end
      end
    end

  end
end
