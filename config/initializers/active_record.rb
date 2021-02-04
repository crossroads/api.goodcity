# # Add time zones by default
# require 'active_record/connection_adapters/postgresql_adapter'

# module ActiveRecord
#   module ConnectionAdapters
#     class PostgreSQLAdapter

#       # override default rails 6 behavior so we can add precision to the
#       # correct part of the data type (see below)
#       def supports_datetime_with_precision?
#         false
#       end

#       unless Rake.application.top_level_tasks.include? "db:test:load_schema"
#         NATIVE_DATABASE_TYPES.merge!(
#           timestamp: { name: "TIMESTAMP(6) WITH TIME ZONE" },
#           datetime:  { name: "TIMESTAMP(6) WITH TIME ZONE" }
#         )
#       end
#     end
#   end
# end
