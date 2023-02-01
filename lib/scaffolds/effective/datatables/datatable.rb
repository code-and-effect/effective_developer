class <%= resource.module_name %><%= resource.module_namespaced %>Datatable < Effective::Datatable
  datatable do
    order :updated_at

    col :updated_at, visible: false
    col :created_at, visible: false
    col :id, visible: false

<% if resource.belong_tos.present? || resource.has_anys.present? -%>
<% resource.belong_tos.each do |reference| -%>
    col :<%= reference.name %>
<% end -%>
<% resource.has_anys.each do |reference| -%>
    col :<%= reference.name %>
<% end -%>

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
