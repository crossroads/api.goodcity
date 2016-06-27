require 'rails_helper'

RSpec.describe Delivery, type: :model do
  describe 'Association' do
    it { is_expected.to belong_to :schedule }
    it { is_expected.to belong_to :offer }
    it { is_expected.to belong_to :contact }
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "successful delivery plan" do
    it "should send notification for new message" do
      delivery = create :drop_off_delivery, schedule: nil
      expect(delivery).to receive(:notify_reviewers)
      delivery.update_attributes(schedule_id: (create :drop_off_schedule).id)
    end
  end

  describe "push_back_offer_state" do
    it "revert offer state on delivery deletion" do
      delivery = create :drop_off_delivery
      offer = delivery.offer
      expect{
        delivery.destroy
      }.to change(offer,:state).from("scheduled").to("reviewed")
    end
  end

  describe "update_offer_state" do
    it "updates offer-state to 'scheduled'" do
      offer = create :offer, :reviewed
      drop_off_delivery = create :drop_off_delivery, offer: offer, schedule: nil
      schedule = create :drop_off_schedule
      expect {
        drop_off_delivery.schedule = schedule
        drop_off_delivery.save
      }.to change(offer, :state).to("scheduled")
    end
  end

end
