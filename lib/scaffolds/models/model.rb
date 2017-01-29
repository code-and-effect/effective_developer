<% module_namespacing do -%>
class <%= resource.class_name %> < <%= parent_class_name.classify %>
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %><%= ', polymorphic: true' if attribute.polymorphic? %><%= ', required: true' if attribute.required? %>
<% end -%>
<% if attributes.all? { |attribute| attribute.respond_to?(:token?) } -%>
<% attributes.select(&:token?).each do |attribute| -%>
  has_secure_token<% if attribute.name != "token" %> :<%= attribute.name %><% end %>
<% end -%>
<% end -%>
<% if attributes.any? { |att| att.respond_to?(:password_digest?) && att.password_digest? } -%>
  has_secure_password
<% end -%>

  # Attributes
<% attributes.each do |attribute| -%>
  # <%= attribute.name.ljust(max_attribute_name_length) %> :<%= attribute.type %>
<% end -%>
<% if archived_attribute.present? -%>

  scope :<%= plural_table_name %>, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
<% end -%>

<% attributes.each do |attribute| -%>
  validates :<%= attribute.name %>, presence: true
<% end -%>

<% if to_s_attribute.present? -%>
  def to_s
    <%= to_s_attribute.name %> || 'New <%= resource.human_name %>'
  end
<% else -%>
  def to_s
    '<%= resource.human_name %>'
  end
<% end -%>
<% if archived_attribute.present? -%>

  def destroy
    update_column(:archived, true) # This intentionally skips validation
  end

  def unarchive
    update_column(:archived, false) # This intentionally skips validation
  end
<% end -%>

end
<% end -%>
