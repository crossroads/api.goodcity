require 'rails_helper'

RSpec.describe AppointmentSlot, type: :model do

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:timestamp).of_type(:datetime) }
    it { is_expected.to have_db_column(:quota).of_type(:integer) }
    it { is_expected.to have_db_column(:note).of_type(:string) }
  end

  describe 'Live updates' do
    let(:push_service) { PushService.new }
    let!(:appointment_slot) { create(:appointment_slot, timestamp: Time.now) }

    before(:each) do
      allow(PushService).to receive(:new).and_return(push_service)
    end

    it "should call push_changes upon change" do
      expect(appointment_slot).to receive(:push_changes)
      appointment_slot.timestamp = Time.now + 1.day
      appointment_slot.save
    end

    it "should only send changes to the Stock channel" do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels.length).to eq(1)
        expect(channels).to include(Channel::STOCK_CHANNEL)
      end
      appointment_slot.timestamp = Time.now + 1.day
      appointment_slot.save
    end
  end
end
