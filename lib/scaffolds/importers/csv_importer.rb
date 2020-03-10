module CsvImporters
  class <%= klass %>Importer < Effective::CsvImporter
    def columns
      {<% columns.each_with_index do |column, index| %>
        <%= column.to_s.underscore.tap { |name| [' ', '/', '(', ')', '__'].each { |str| name.gsub!(str, '_') } }.to_sym %>: <%= (letters[index] || index) %><%= ',' unless (index+1) == columns.length %><% end %>
      }
    end

    def process_row
      # assign_columns(<%= klass.singularize %>.new).save!
      raise 'todo'
    end
  end
end
