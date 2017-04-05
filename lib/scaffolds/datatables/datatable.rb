class <%= resource.namespaced_class_name.pluralize %>Datatable < Effective::Datatable
<% if resource.scopes.present? -%>
  filters do<% ([:all] + resource.scopes).uniq.each_with_index do |scope, index| %>
    scope :<%= scope -%><%= ', default: true' if index == 0 -%>
<% end %>
  end

<% end -%>
  datatable do
    order :<%= (attributes.find { |att| att.name == 'updated_at' } || attributes.first).name -%>, :desc

<% resource.belong_tos.each do |reference| -%>
    col :<%= reference.name %>
<% end -%>

<% attributes.each do |attribute| -%>
    col :<%= attribute.name %>
<% end -%>

<% if non_crud_actions.present? -%>
    actions_col do |<%= singular_name %>|
<% non_crud_actions.each_with_index do |action, index| -%>
      glyphicon_to('ok', <%= resource.action_path_helper(action, at: false) %>, title: '<%= action.titleize %>')<%= ' +' if (index+1) < (invoked_actions - crud_actions).length %>
<% end -%>
    end
<% else -%>
    actions_col
<% end -%>
  end

<% if resource.scopes.blank? -%>
  collection do
    <%= resource.class_name %>.all
  end
<% else -%>
  collection do
    <%= resource.class_name %>.all
  end
<% end -%>

end
