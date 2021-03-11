require 'rails_helper'
require 'active_record'

describe "Migrate OrderTransports to have scheduled_at as DateTime instead of date", type: :migration do

  let(:migration) { load_migration('20181121040221_change_order_transport_scheduled_at_to_datetime') }

  before do
    migration.down if migration.has_run?
  end

  after do
    migration.up unless migration.has_run?
  end

  def type_of(column)
    open_table(:order_transports).column_type(column)
  end

  def get_column_for_id(column, id)
    open_table(:order_transports).column_value(id, column)
  end

  it 'Should change the type of scheduled_at from Date to DateTime' do
    record_id = FactoryBot.create(:order_transport, scheduled_at: Date.parse('2018-03-17'), timeslot: '2PM-3PM').id

    expect(type_of('scheduled_at')).to eq('date')
    expect(OrderTransport.count).to eq(1)
    expect(get_column_for_id('scheduled_at', record_id)).to eq('2018-03-17')

    migration.up

    expect(type_of('scheduled_at')).to eq('timestamp with time zone')
    expect(OrderTransport.count).to eq(1)

    new_timestamp = DateTime.parse(get_column_for_id('scheduled_at', record_id).to_s).in_time_zone
    expect(new_timestamp.in_time_zone.hour).to eq(14)
    expect(new_timestamp.in_time_zone.min).to eq(0)
    expect(new_timestamp.utc.to_s).to eq('2018-03-17 06:00:00 UTC')
  end

end
