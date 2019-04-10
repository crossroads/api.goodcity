require 'rails_helper'

RSpec.describe AppointmentSlotPreset, type: :model do

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:day).of_type(:integer) }
    it { is_expected.to have_db_column(:hours).of_type(:integer) }
    it { is_expected.to have_db_column(:minutes).of_type(:integer) }
    it { is_expected.to have_db_column(:quota).of_type(:integer) }
  end

  describe 'Live updates' do
    let(:push_service) { PushService.new }
    let!(:appointment_slot_preset) { create(:appointment_slot_preset, hours: 1) }

    before(:each) do
      allow(PushService).to receive(:new).and_return(push_service)
    end

    it "should call push_changes upon change" do
      expect(appointment_slot_preset).to receive(:push_changes)
      appointment_slot_preset.hours = 2
      appointment_slot_preset.save
    end


    it "should only send changes to the stock channel" do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels.length).to eq(1)
        expect(channels).to include(Channel::STOCK_CHANNEL)
      end
      appointment_slot_preset.hours = 2
      appointment_slot_preset.save
    end
  end
end
