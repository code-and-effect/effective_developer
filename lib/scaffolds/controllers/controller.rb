class <%= resource.namespaced_class_name.pluralize %>Controller < <%= [resource.namespace.try(:classify).presence, ApplicationController].compact.join('::') %>
  include Effective::CrudController
end
