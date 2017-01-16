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

    actions_column
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
