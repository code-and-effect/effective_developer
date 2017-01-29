require 'effective_resources'
require 'generators/effective/helpers'
require 'effective_developer/engine'
require 'effective_developer/version'

module EffectiveDeveloper

  def self.setup
    yield self
  end

  def self.authorized?(controller, action, resource)
    if authorization_method.respond_to?(:call) || authorization_method.kind_of?(Symbol)
      raise Effective::AccessDenied.new() unless (controller || self).instance_exec(controller, action, resource, &authorization_method)
    end
    true
  end

end
