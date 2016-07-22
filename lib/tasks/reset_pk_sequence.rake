desc 'Reset all database table PK sequences. Fixes duplicate key violates unique constraint (id) error'
task :reset_pk_sequence => :environment do
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.reset_pk_sequence!(table)
  end
end
