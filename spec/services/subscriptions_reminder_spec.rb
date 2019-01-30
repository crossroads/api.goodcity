require 'rails_helper'

describe SubscriptionsReminder do
  let(:user_with_offer)  { create :user, :with_offer }
  let(:reviewer)         { create :user, :reviewer }
  let(:offer)            { user_with_offer.offers.first }
  let(:delta)            { SUBSCRIPTION_REMINDER_TIME_DELTA }
  let(:before_delta)     { delta + 2.hours } # a time over '4' hours ago
  let(:after_delta)      { delta - 2.hours } # a time less than '4' hours ago

  subject { SubscriptionsReminder.new }
  
  let!(:message) { create(:message, offer: offer, sender: reviewer) }

  context "check spec setup" do
    it "correctly forms the test conditions" do
      expect(Subscription.where(user: user_with_offer, offer: offer, message: message, state: 'unread').count).to eql(1)
      expect(user_with_offer.offers.count).to eql(1)
      expect(user_with_offer.sms_reminder_sent_at).to eql(nil)
      expect(Offer.count).to eql(1)
      expect(Message.count).to eql(1)
    end
  end

  context "user_candidates_for_reminder" do

    context "includes user when" do
      it "there is a new unread message and we last reminded the user over X hours ago " do
        expect(user_with_offer.subscriptions.unread.first.message.created_at).to be > delta.ago
        user_with_offer.update_attribute(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([user_with_offer])
      end
      it "there is a new unread message, we've never sent a before reminder, and it's now over X hours since they were created" do
        expect(user_with_offer.subscriptions.unread.first.message.created_at).to be > delta.ago
        user_with_offer.update_attribute(:created_at, before_delta.ago)
        user_with_offer.update_attribute(:sms_reminder_sent_at, nil)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([user_with_offer])
      end
      it "2 new unread messages created after we last reminded the user - only sends one reminder" do
        msg2 = create(:message, offer: offer, sender: reviewer)
        user_with_offer.update_attribute(:sms_reminder_sent_at, before_delta.ago)
        expect(user_with_offer.subscriptions.unread.size).to eql(2)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([user_with_offer])
      end
    end

    context "doesn't include user when" do
      it "there is a new unread message but we last reminded the user less than X hours ago" do
        expect(user_with_offer.subscriptions.unread.first.message.created_at).to be > delta.ago
        user_with_offer.update_attribute(:sms_reminder_sent_at, after_delta.ago)
        expect(user_with_offer.sms_reminder_sent_at).to be > delta.ago
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end
      it "there is a new unread message but user signed up less than X hours ago" do
        expect(user_with_offer.subscriptions.unread.first.message.created_at).to be > delta.ago
        user_with_offer.update_attribute(:created_at, after_delta.ago)
        user_with_offer.update_attribute(:sms_reminder_sent_at, nil)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end
      it "a new message (created since the user was last reminded) has already been read" do
        user_with_offer.subscriptions.unread.first.update_attribute(:state, 'read')
        user_with_offer.update_attribute(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end
      it "the message was sent by the user themselves" do
        message.update_attribute(:sender_id, user_with_offer.id)
        user_with_offer.update_attribute(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end
      it "no new messages created since we last reminded them" do
        user_with_offer.update_attribute(:sms_reminder_sent_at, before_delta.ago)
        message.update_attribute(:created_at, (before_delta + 1).ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end
      it "user is not a donor (has no offers)" do
        Offer.all.each{|offer| offer.update_attribute(:created_by_id, nil) }
        user_with_offer.update_attribute(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end
    end
  end

end
