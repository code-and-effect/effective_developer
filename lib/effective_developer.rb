require 'effective_resources'
require 'generators/effective/helpers'
require 'effective_developer/engine'
require 'effective_developer/version'

module EffectiveDeveloper
  mattr_accessor :live

  def self.setup
    yield self
  end

end
