<% if resource.module_name.present? -%>
module <%= resource.module_name %>
  class <%= resource.module_namespaced %>Controller < <%= resource.module_namespace %>ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::CrudController
  end
end
<% else -%>
class <%= resource.namespaced_class_name.pluralize %>Controller < <%= resource.module_namespace %>ApplicationController
  before_action(:authenticate_user!) if defined?(Devise)

  include Effective::CrudController
end
<% end -%>
