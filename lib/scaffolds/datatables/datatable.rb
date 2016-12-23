module Effective
  module Datatables
    class <%= namespaced_class_name %> < Effective::Datatable

      datatable do<% attributes.each do |attribute| %>
        table_column :<%= attribute.name -%>
<% end %>

        actions_column
      end

      def collection
        <%= class_name %>.all
      end

    end
  end
end
