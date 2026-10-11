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
      delivery.update(schedule_id: (create :drop_off_schedule).id)
    end
  end

  describe "the reviewers' push text" do
    # API-61: an Alternate ("Crossroads collects") booking looked up delivery.alternate_message, which didn't exist.
    { crossroads_delivery: "Crossroads will collect", drop_off_delivery: "will deliver the items",
      self_arranged_van_delivery: "their own van will arrive" }.each do |factory, words|
      it "is a real sentence for #{factory} in English and Chinese" do
        delivery = create factory
        text = I18n.with_locale(:en) { delivery.send(:delivery_notify_message) }
        expect(text).to include(words)
        expect(text).not_to match(/translation missing/i)
        expect(text).to include(delivery.offer.created_by.full_name)
        # zh-tw: the sentence exists. (Its date still says "translation missing" for every type, because
        # `day.ordinalize` has no zh-tw rule — a separate, older fault, logged as its own issue.)
        key = "delivery.#{delivery.delivery_type.downcase.tr(' ', '_')}_message"
        expect(I18n.exists?(key, :"zh-tw")).to eq(true)
      end
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

    it "updates offer-state to 'scheduled' for a self-arranged van delivery" do
      offer = create :offer, :reviewed
      self_arranged_van_delivery = create :self_arranged_van_delivery, offer: offer, schedule: nil
      schedule = create :drop_off_schedule
      expect {
        self_arranged_van_delivery.schedule = schedule
        self_arranged_van_delivery.save
      }.to change(offer, :state).to("scheduled")
    end
  end

end
