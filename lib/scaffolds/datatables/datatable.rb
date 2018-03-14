class <%= resource.namespaced_class_name.pluralize %>Datatable < Effective::Datatable

  datatable do
    order :<%= (attributes.find { |att| att.name == 'updated_at' } || attributes.first).name %>

<% if attributes.find { |att| att.name == 'updated_at' } -%>
    col :updated_at, visible: false
<% end -%>
<% if attributes.find { |att| att.name == 'created_at' } -%>
    col :created_at, visible: false
<% end -%>
<% if attributes.find { |att| att.name == 'id' } -%>
    col :id, visible: false

<% end -%>
<% resource.belong_tos.each do |reference| -%>
    col :<%= reference.name %>
<% end -%>
<% resource.nested_resources.each do |reference| -%>
    col :<%= reference.name %>
<% end -%>
<% attributes.reject { |att| ['created_at', 'updated_at', 'id'].include?(att.name) }.each do |attribute| -%>
    col :<%= attribute.name %>
<% end -%>

<% if non_crud_actions.present? -%>
    actions_col do |<%= singular_name %>|
<% non_crud_actions.each_with_index do |action, index| -%>
      icon_to('ok', <%= resource.action_path_helper(action, at: false) %>, title: '<%= action.titleize %>')<%= ' +' if (index+1) < (invoked_actions - crud_actions).length %>
<% end -%>
    end
<% else -%>
    actions_col
<% end -%>
  end

  collection do
    <%= resource.class_name %>.deep.all
  end

end
