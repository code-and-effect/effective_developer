require 'effective_resources'
require 'rails/generators'
require 'generators/effective/helpers'
require 'effective_developer/engine'
require 'effective_developer/version'

module EffectiveDeveloper

  def self.config_keys
    [:live]
  end

  include EffectiveGem

end
