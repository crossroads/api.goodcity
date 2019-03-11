require 'rails_helper'
require "rspec/mocks/standalone"

RSpec.describe OrderTransport, type: :model do

  describe "Associations" do
    it { is_expected.to belong_to :order  }
    it { is_expected.to belong_to :contact }
    it { is_expected.to belong_to :gogovan_order }
    it { is_expected.to belong_to :gogovan_transport }
  end

  describe 'Database columns' do
    #it{ is_expected.to have_db_column(:scheduled_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:timeslot).of_type(:string)}
    it{ is_expected.to have_db_column(:transport_type).of_type(:string)}
    it{ is_expected.to have_db_column(:remove_net).of_type(:string)}
    it{ is_expected.to have_db_column(:contact_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:gogovan_order_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:gogovan_transport_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:order_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:created_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:updated_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:need_english).of_type(:boolean)}
    it{ is_expected.to have_db_column(:need_cart).of_type(:boolean)}
    it{ is_expected.to have_db_column(:need_carry).of_type(:boolean)}
    it{ is_expected.to have_db_column(:need_over_6ft).of_type(:boolean)}
  end

  describe 'Schedule' do

    it 'Should inject timeslot intp the scheduled_at timestamp' do
      record = FactoryBot.create(:order_transport, scheduled_at: Date.parse('2018-03-17'), timeslot: '2PM-3PM')
      #expect(record.scheduled_at.in_time_zone.hour).to eq(14)
      expect(record.scheduled_at.in_time_zone.min).to eq(0)
      expect(record.scheduled_at.utc.to_s).to eq('2018-03-17 06:00:00 UTC')

      record2 = FactoryBot.create(:order_transport, scheduled_at: Date.parse('2018-03-17'), timeslot: '10:30AM-3PM')
      expect(record2.scheduled_at.in_time_zone.hour).to eq(10)
      expect(record2.scheduled_at.in_time_zone.min).to eq(30)
      expect(record2.scheduled_at.utc.to_s).to eq('2018-03-17 02:30:00 UTC')

      record3 = FactoryBot.create(:order_transport, scheduled_at: Date.parse('2018-03-17'), timeslot: '09AM')
      expect(record3.scheduled_at.in_time_zone.hour).to eq(9)
      expect(record3.scheduled_at.in_time_zone.min).to eq(0)
      expect(record3.scheduled_at.utc.to_s).to eq('2018-03-17 01:00:00 UTC')

      record4 = FactoryBot.create(:order_transport, scheduled_at: Date.parse('2018-03-17'), timeslot: 'invalid_format')
      expect(record4.scheduled_at.in_time_zone.hour).to eq(0)
      expect(record4.scheduled_at.in_time_zone.min).to eq(0)
      expect(record4.scheduled_at.utc.to_s).to eq('2018-03-16 16:00:00 UTC')
    end

  end

end
