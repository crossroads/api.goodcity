require 'rails_helper'

describe SubscriptionsReminder do
  let(:offer) { create :offer }
  let(:user) { offer.created_by }
  let!(:subscription) { create(:subscription, user: user, state:'unread' ) }
  let!(:subscription1) { create(:subscription, user: user, offer: offer, state:'unread', sms_reminder_sent_at: ((SUBSCRIPTION_REMINDER_TIME_DELTA+1).ago) ) }
  let!(:subscription2) { create(:subscription, user: user, offer: offer, state:'unread', sms_reminder_sent_at: ((SUBSCRIPTION_REMINDER_TIME_DELTA-2).ago) ) }
  let(:subscription_reminder) { SubscriptionsReminder.new }
  let(:time) { Time.now }

  before(:each) do
    allow(Time).to receive(:now).and_return(time)
  end

  context "generate" do
    it "sends sms of unread messages if sms_reminder_sent_at is nil" do
      subscription_reminder.generate
      expect(subscription.reload.sms_reminder_sent_at.to_s(:db)).to eq(time.to_s(:db))
    end

    it "sends sms of unread messages if sms_reminder_sent_at gap time is more than 4 hours" do
      subscription_reminder.generate
      expect(subscription1.reload.sms_reminder_sent_at.to_s(:db)).to eq(time.to_s(:db))
    end

    it "do not sends sms of unread messages if sms_reminder_sent_at gap time is less than 4 hours" do
      expect{ subscription_reminder.generate}.to_not change(Subscription.find(subscription2.id), :sms_reminder_sent_at)
    end
  end
end
