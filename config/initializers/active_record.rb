# Add time zones by default
require 'active_record/connection_adapters/postgresql_adapter'
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES.merge!(
  timestamp: { name: "TIMESTAMP(6) WITH TIME ZONE" }
 )
