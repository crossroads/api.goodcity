require 'rails_helper'

context PushUpdatesForDelivery do

  let(:delivery) { create :delivery }
  let(:operation) { 'create' }
  let(:data) { {} }
  let(:donor) { delivery.offer.created_by }
  let(:push_service) { PushService.new }
  let(:staff_channel) { Channel::STAFF_CHANNEL }
  let(:donor_channel) { ["user_#{donor.id}"] }
  let(:reviewer) { create :user, :reviewer }

  before(:each) do
    allow(PushService).to receive(:new).and_return(push_service)
  end

  context "send_updates" do
    it "should call push_updates" do
      expect(delivery).to receive(:push_updates)
      delivery.send_updates(operation)
    end
  end
  
  context "push_updates" do
    it "sends push updates to donor and admin" do
      expect(push_service).to receive(:send_update_store).with(staff_channel, ADMIN_APP, data)
      expect(push_service).to receive(:send_update_store).with(donor_channel, DONOR_APP, data)
      delivery.send(:push_updates, data)
    end
  end

  context "serialized_sender" do
    it "should be the donor" do
      allow(User).to receive(:current_user).and_return(nil)
      expect(delivery.send(:serialized_sender).id).to eq(donor.id)
    end

    it "should be the admin" do
      allow(User).to receive(:current_user).and_return(reviewer)
      expect(delivery.send(:serialized_sender).id).to eq(reviewer.id)
    end
  end

end