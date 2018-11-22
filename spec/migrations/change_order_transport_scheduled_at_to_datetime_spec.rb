require 'rails_helper'
require 'active_record'

require Rails.root.join('db/migrate/20181121040221_change_order_transport_scheduled_at_to_datetime')

describe "Migrate OrderTransports to have scheduled_at as DateTime instead of date", type: :migration do

  MIGRATION_VERSION = "20181121040221"

  let(:migration) { ChangeOrderTransportScheduledAtToDatetime.new }

  def migration_has_been_run?(version)
    table_name = ActiveRecord::Migrator.schema_migrations_table_name
    query = "SELECT version FROM %s WHERE version = '%s'" % [table_name, version]
    ActiveRecord::Base.connection.execute(query).any?
  end

  before do
    if migration_has_been_run?(MIGRATION_VERSION)
      migration.migrate(:down)
    end
  end

  after do
    unless migration_has_been_run?(MIGRATION_VERSION)
      migration.migrate(:up)
    end
  end

  def type_of(column)
    res = ActiveRecord::Base.connection.execute <<-SQL 
      SELECT data_type
      FROM information_schema.columns
      WHERE table_name = 'order_transports' and column_name = '#{column}'
    SQL
    res.first['data_type']
  end

  def get_column_for_id(column, id)
    res = ActiveRecord::Base.connection.execute <<-SQL 
      SELECT #{column}
      FROM order_transports
      WHERE id = #{id}
    SQL
    return res.first[column]
  end

  it 'Should change the type of scheduled_at from Date to DateTime' do
    record_id = FactoryBot.create(:order_transport, scheduled_at: Date.parse('2018-03-17'), timeslot: '2PM-3PM').id

    expect(type_of('scheduled_at')).to eq('date')
    expect(OrderTransport.count).to eq(1)
    expect(get_column_for_id('scheduled_at', record_id)).to eq('2018-03-17')

    migration.up

    expect(type_of('scheduled_at')).to eq('timestamp without time zone')
    expect(OrderTransport.count).to eq(1)

    new_timestamp = DateTime.parse(get_column_for_id('scheduled_at', record_id)).in_time_zone
    expect(new_timestamp.in_time_zone.hour).to eq(14) 
    expect(new_timestamp.in_time_zone.min).to eq(0) 
    expect(new_timestamp.utc.to_s).to eq('2018-03-17 06:00:00 UTC') 
  end

end