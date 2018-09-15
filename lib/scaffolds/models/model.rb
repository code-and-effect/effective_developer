<% module_namespacing do -%>
class <%= resource.class_name %> < <%= parent_class_name.classify %>
<% resource.belong_tos.each do || ass -%>
  belongs_to :<%= ass.name %><%= ', polymorphic: true' if ass.polymorphic? %>
<% end -%>

  effective_resource do
<% invoked_attributes.each do |name, (type, _)| -%>
    <%= name.to_s.ljust(max_attribute_name_length) %> :<%= type %>
<% end -%>

    timestamps
  end

  scope :deep, -> { all }

<% invoked_attributes.each do |name, (type, _)| -%>
  validates :<%= name %>, presence: true
<% end -%>

  def to_s
<% if to_s_attribute.present? -%>
    <%= to_s_attribute %> || 'New <%= resource.human_name %>'
<% else %>
    '<%= resource.human_name %>'
<% end -%>
  end

end
<% end -%>
