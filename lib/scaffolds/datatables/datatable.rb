class <%= resource.namespaced_class_name.pluralize %>Datatable < Effective::Datatable

  bulk_actions do
    bulk_action 'Delete selected', <%= [resource.namespaces, resource, 'path'].flatten.compact.join('_') %>(:ids), data: { method: :delete, confirm: 'Really delete selected?' }
  end

  datatable do
    order :updated_at

    bulk_actions_col

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
