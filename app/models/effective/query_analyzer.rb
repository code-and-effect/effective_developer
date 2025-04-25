module Effective
  class QueryAnalyzer
    def instrument_queries(ignore: [])
      ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        query = event.payload[:sql]
        name = args.last[:name]

        ignored_actions = ['EXPLAIN ANALYZE', 'BEGIN', 'COMMIT', 'ROLLBACK', 'SET']
        ignored_methods = ['SCHEMA', 'ActiveRecord::SchemaMigration Load']

        ignored = (event.duration < 1.0) # Ignore queries that take less than 1ms
        ignored ||= query.exclude?('WHERE') # We're only interested in queries that use a WHERE clause
        ignored ||= ignored_actions.any? { |action| query.start_with?(action) }
        ignored ||= ignored_methods.any? { |method| name.to_s.include?(method) }
        ignored ||= ignore.any? { |ignore| name.to_s.include?(ignore) }

        unless ignored
          # Get the execution plan
          plan = ActiveRecord::Base.logger.silence do
            ActiveRecord::Base.connection.execute("EXPLAIN ANALYZE #{query}").to_a.join("\n")
          end

          # Check for sequential scans
          if plan.include?('Seq Scan')
            Rails.logger.error "⚠️ Sequential Scan Detected (#{name}) ⚠️"
            Rails.logger.error "Query: #{query}"
            Rails.logger.error "Plan:\n#{plan}"
          end
        end
      end
    end
  end
end
