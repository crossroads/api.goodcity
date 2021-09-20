# Add time zones by default
require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter

      # override default rails 6 behavior so we can add precision to the
      # correct part of the data type (see below)
      def supports_datetime_with_precision?
        false
      end

      NATIVE_DATABASE_TYPES.merge!(
        datetime:  { name: "TIMESTAMP WITH TIME ZONE" },
        timestamp: { name: "TIMESTAMP WITH TIME ZONE" }
      )
    end
  end
end
