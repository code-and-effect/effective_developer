class <%= resource.namespaced_class_name.pluralize %>Datatable < Effective::Datatable

  datatable do
    length 25
    order :<%= (attributes[:updated_at] ? :updated_at : attributes.keys.first) %>

<% if attributes[:updated_at] -%>
    col :updated_at, visible: false
<% end -%>
<% if attributes[:created_at] -%>
    col :created_at, visible: false
<% end -%>
    col :id, visible: false

<% resource.belong_tos.each do |reference| -%>
    col :<%= reference.name %>
<% end -%>
<% resource.nested_resources.each do |reference| -%>
    col :<%= reference.name %>
<% end -%>

<% attributes.except(:created_at, :updated_at, :id).each do |name, _| -%>
    col :<%= name %>
<% end -%>

    actions_col
  end

  collection do
    <%= resource.class_name %>.deep.all
  end

end
