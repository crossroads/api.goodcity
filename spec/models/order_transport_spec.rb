require 'rails_helper'
require "rspec/mocks/standalone"

RSpec.describe OrderTransport, type: :model do

  describe "Associations" do
    it { is_expected.to belong_to :order  }
    it { is_expected.to belong_to :contact }
    it { is_expected.to belong_to :gogovan_order }
    it { is_expected.to belong_to :gogovan_transport }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:order_id) }
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

  describe "Live updates" do
    let!(:push_service) { PushService.new }
    let!(:user) { create :user }
    let!(:order) { create :order, created_by: user }
    let!(:order_transport) { create :order_transport, order: order }
    let(:user_browse_channel) { "user_#{user.id}_browse" }

    before(:each) do
      allow(PushService).to receive(:new).and_return(push_service)
    end

    it "should call push_changes upon change" do
      expect(order_transport).to receive(:push_changes)
      order_transport.scheduled_at = Time.now + 10.days
      order_transport.save
    end

    it "should send changes to the browse app of the social worker" do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels.flatten).to include(user_browse_channel)
      end
      order_transport.scheduled_at = Time.now + 10.days
      order_transport.save
    end

    it "should not send changes to any other browse user" do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        channels -= [ user_browse_channel]
        channels.each do |c|
          expect(c).not_to include('browse')
        end
      end
      order_transport.scheduled_at = Time.now + 10.days
      order_transport.save
    end

    it "should send changes to the stock app via the ORDER_FULFILMENT_CHANNEL" do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels.length).to eq(2)
        expect(channels).to include(Channel::ORDER_FULFILMENT_CHANNEL)
      end
      order_transport.scheduled_at = Time.now + 10.days
      order_transport.save
    end
  end

  describe "#pickup?" do
    let (:order) { create(:order, :with_state_submitted) }
    let (:order_transport) { create(:order_transport, transport_type: "self", order_id: order.id) }
    let (:order2) { create(:order, :with_state_submitted) }
    let (:order_transport2) { create(:order_transport, transport_type: "ggv", order_id: order2.id) }

    it "returns true if transport type is self" do
      expect(order_transport.pickup?).to be_truthy
    end
    it "returns true if transport type is not self" do
      expect(order_transport2.pickup?).to be_falsey
    end
  end
end
