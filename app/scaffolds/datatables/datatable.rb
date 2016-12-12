module Effective
  module Datatables
    class <%= class_name %> < Effective::Datatable

      datatable do
      <% attributes.each do |attribute| %>
        table_column :<%= attribute.name -%>
      <% end %>
        actions_column
      end

    end
  end
end
