class <%= resource.namespaced_class_name.pluralize %>Datatable < Effective::Datatable
<% if resource.scopes.present? -%>
  scopes do<% ([:all] + resource.scopes).uniq.each_with_index do |scope, index| %>
    scope :<%= scope -%><%= ', default: true' if index == 0 -%>
<% end %>
  end

<% end -%>
  datatable do
    default_order :<%= (attributes.find { |att| att.name == 'updated_at' } || attributes.first).name -%>, :desc

<% resource.belong_tos.each do |reference| -%>
    table_column :<%= reference.name %>
<% end -%>

<% attributes.each do |attribute| -%>
    table_column :<%= attribute.name %>
<% end -%>

<% if non_crud_actions.present? -%>
    actions_column do |<%= singular_name %>|
<% non_crud_actions.each_with_index do |action, index| -%>
      glyphicon_to('ok', <%= resource.action_path_helper(action, at: false) %>, title: '<%= action.titleize %>')<%= ' +' if (index+1) < (invoked_actions - crud_actions).length %>
<% end -%>
    end
<% else -%>
    actions_column
<% end -%>
  end

<% if resource.scopes.blank? -%>
  def collection
    <%= resource.class_name %>.all
  end
<% else -%>
  def collection
    col = <%= resource.class_name %>.all
    col = col.send(current_scope) if current_scope
    col
  end
<% end -%>

end
