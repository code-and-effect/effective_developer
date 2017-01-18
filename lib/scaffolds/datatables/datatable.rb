class <%= namespaced_class_name %>Datatable < Effective::Datatable
<% if scopes.present? -%>

  scopes do<% ([:all] + scopes).uniq.each do |scope| %>
    scope :<%= scope -%>
<% end %>
  end

<% end -%>
  datatable do<% attributes.each do |attribute| %>
    table_column :<%= attribute.name -%>
<% end %>

<% if (invoked_actions - crud_actions).present? -%>
    actions_column do |<%= singular_name %>|
<% (invoked_actions - crud_actions).each do |action| -%>
      glyphicon_to('ok', <%= action_path(:mark_as_paid, at: false) %>, title: '<%= action.titleize %>')
<% end -%>
    end
<% else -%>
    actions_column
<% end -%>
  end

<% if scopes.blank? -%>
  def collection
    <%= class_name %>.all
  end
<% else -%>
  def collection
    col = <%= class_name %>.all
    col = col.send(current_scope) if current_scope
    col
  end
<% end -%>

end
