module Admin
  class <%= resource.class_name.sub('Effective::', '') %>Controller < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :<%= effective_gem_name %>) }

    include Effective::CrudController

    private

    def permitted_params
      params.require(:<%= resource.resource_name %>).permit!
    end

  end
end
