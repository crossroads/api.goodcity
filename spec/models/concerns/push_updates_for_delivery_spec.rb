require 'rails_helper'

context PushUpdatesForDelivery do

  let!(:delivery) { create :drop_off_delivery }
  let(:operation) { 'create' }
  let(:data) { {} }
  let(:donor) { delivery.offer.created_by }
  let(:push_service) { PushService.new }
  let(:donor_channel) { ["user_#{donor.id}"] }
  let(:reviewer) { create :user, :reviewer }

  before(:each) do
    allow(PushService).to receive(:new).and_return(push_service)
  end

  context "send_updates for" do
    context "drop_off_delivery" do
      it "should call push_updates with delivery and schedule records" do
        expect(delivery).to receive(:serialized_object).with(delivery)
        expect(delivery).to receive(:serialized_object).with(delivery.schedule)
        expect(delivery).to receive(:push_updates).twice
        delivery.send_updates(operation)
      end
    end
    context "gogovan_delivery" do
      let!(:delivery) { create :gogovan_delivery }
      it "should call push_updates with delivery, schedule, contact and address records" do
        expect(delivery).to receive(:serialized_object).with(delivery)
        expect(delivery).to receive(:serialized_object).with(delivery.schedule)
        expect(delivery).to receive(:serialized_object).with(delivery.contact)
        expect(delivery).to receive(:serialized_object).with(delivery.contact.address)
        expect(delivery).to receive(:serialized_object).with(delivery.gogovan_order)
        expect(delivery).to receive(:push_updates).exactly(5).times
        delivery.send_updates(operation)
      end
    end
  end
  
  context "push_updates" do
    it "to donor and admin" do
      expect(push_service).to receive(:send_update_store).with(Channel::STAFF_CHANNEL, data)
      expect(push_service).to receive(:send_update_store).with(donor_channel, data)
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

  context "notify_reviewers" do
    it do
      expect(push_service).to receive(:send_notification) do |channel, app_name, data|
        expect(channel).to eql(Channel::REVIEWER_CHANNEL)
        expect(app_name).to eql(ADMIN_APP)
        expect(data[:category]).to eq('offer_delivery')
      end
      delivery.notify_reviewers
    end
  end

end
