class <%= namespaced_class_name %>Datatable < Effective::Datatable

  datatable do<% attributes.each do |attribute| %>
    table_column :<%= attribute.name -%>
<% end %>

    actions_column
  end

  def collection
    <%= class_name %>.all
  end

end
