# frozen_string_literal: true
# Effective::ContentReplacer.new.replace!("foo", "bar")

module Effective
  class ContentReplacer
    attr_accessor :places

    def initialize(places = nil)
      @places = (places || default_places)
    end

    def default_places
      { action_text_rich_texts: [:body] }
    end

    def replace!(old_value, new_value)
      raise("old_value cannot contain a \' character") if old_value.include?("'")
      raise("new_value cannot contain a \' character") if new_value.include?("'")

      total = 0
  
      places.each do |table, columns|
        columns.each do |column|
          sql = "SELECT COUNT(*) FROM #{table} WHERE #{column} ILIKE '%#{old_value}%'"
          existing = ActiveRecord::Base.connection.execute(sql).first['count'].to_i
          total += existing

          puts "Replacing #{existing} occurrences of #{old_value} with #{new_value} in #{table}.#{column}"

          sql = "UPDATE #{table} SET #{column} = REPLACE(#{column}, '#{old_value}', '#{new_value}') WHERE #{column} ILIKE '%#{old_value}%'"
          ActiveRecord::Base.connection.execute(sql)
        end
      end

      total
    end

    def count(old_value)
      raise("old_value cannot contain a \' character") if old_value.include?("'")

      total = 0

      places.each do |table, columns|
        columns.each do |column|
          sql = "SELECT COUNT(*) FROM #{table} WHERE #{column} ILIKE '%#{old_value}%'"
          existing = ActiveRecord::Base.connection.execute(sql).first['count'].to_i
          total += existing

          puts "There are #{existing} occurrences of #{old_value} in #{table}.#{column}"
        end
      end

     total 
    end
    alias_method :find, :count

  end
end
