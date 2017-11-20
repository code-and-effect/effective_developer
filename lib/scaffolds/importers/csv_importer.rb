module CsvImporters
  class <%= klass %>Importer < Effective::CSVImporter
    def columns
      {<% columns.each_with_index do |column, index| %>
        <%= column.to_s.underscore.gsub(' ', '_').to_sym %>: <%= (letters[index] || index) %><%= ',' unless (index+1) == columns.length %><% end %>
      }
    end

    def process_row
      # assign_columns(<%= klass.singularize %>.new).save!
      raise 'todo'
    end
  end
end
