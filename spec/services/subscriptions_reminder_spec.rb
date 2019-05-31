require 'rails_helper'

describe SubscriptionsReminder do
  let(:donor)        { create(:user) }
  let(:charity)       { create(:user, :charity) }
  let(:reviewer)     { create(:user, :reviewer) }
  let(:supervisor)   { create(:user, :supervisor) }
  let(:offer)        { create(:offer, :submitted, created_by: donor) }
  let(:reviewer_offer) { create(:offer, :submitted, created_by: reviewer) }
  let(:reviewed_offer) { create(:offer, :reviewed, reviewed_by: reviewer, created_by: donor) }
  let(:order)         { create(:order, :with_state_submitted, created_by: charity) }
  let(:charity_offer) { create(:offer, :submitted, created_by: charity) }
  let(:delta)        { SUBSCRIPTION_REMINDER_TIME_DELTA }
  let(:before_delta) { delta + 2.hours } # a time over '4' hours ago
  let(:after_delta)  { delta - 2.hours } # a time less than '4' hours ago

  subject { SubscriptionsReminder.new }

  let!(:message) { create(:message, offer: offer, sender: reviewer) }
  let!(:message1) { create(:message, :with_order, order: order, sender: reviewer) }

  context "check spec setup" do
    it "correctly forms the test conditions" do
      expect(Subscription.where(user: donor, offer: offer, message: message, state: 'unread').count).to eql(1)
      expect(donor.offers.count).to eql(1)
      expect(donor.sms_reminder_sent_at).to eql(nil)
      expect(Offer.count).to eql(1)
      expect(offer.state).to eql('submitted')
      expect(Message.count).to eql(2)
    end
  end

  context "user_candidates_for_reminder" do

    context "includes user when" do
      it "there is a new unread message and we last reminded the user over X hours ago " do
        expect(donor.subscriptions.unread.first.message.created_at).to be > delta.ago
        donor.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([donor])
      end

      it "there is a new unread message, we've never sent a before reminder, and it's now over X hours since they were created" do
        expect(donor.subscriptions.unread.first.message.created_at).to be > delta.ago
        donor.update_columns(created_at: before_delta.ago, sms_reminder_sent_at: nil)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([donor])
      end

      it "2 new unread messages created after we last reminded the user - only sends one reminder" do
        msg2 = create(:message, offer: offer, sender: reviewer)
        donor.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(donor.subscriptions.unread.size).to eql(2)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([donor])
      end

      it "donor's offer is received" do
        Offer.update_all(state: 'received')
        donor.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([donor])
      end

      it "donor's offer is inactive" do
        Offer.update_all(state: 'inactive')
        donor.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([donor])
      end

      it "reviewers own active offer" do
        msg3 = create(:message, offer: reviewer_offer, sender: supervisor)
        reviewer.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([reviewer])
      end

      it "charity user who is also donor has unread message on offer and order both" do
        msg4 = create(:message, offer: charity_offer, sender: reviewer)
        charity.update_column(:sms_reminder_sent_at, before_delta.ago) 
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([charity])
      end
    end

    context "doesn't include user when" do
      it "there is a new unread message but we last reminded the user less than X hours ago" do
        expect(donor.subscriptions.unread.first.message.created_at).to be > delta.ago
        donor.update_column(:sms_reminder_sent_at, after_delta.ago)
        expect(donor.sms_reminder_sent_at).to be > delta.ago
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end

      it "there is a new unread message but user signed up less than X hours ago" do
        expect(donor.subscriptions.unread.first.message.created_at).to be > delta.ago
        donor.update_columns(created_at: after_delta.ago, sms_reminder_sent_at: nil)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end

      it "a new message (created since the user was last reminded) has already been read" do
        donor.subscriptions.unread.first.update_column(:state, 'read')
        donor.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end
      it "the message was sent by the user themselves" do
        message.update_column(:sender_id, donor.id)
        donor.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end

      it "no new messages created since we last reminded them" do
        donor.update_column(:sms_reminder_sent_at, before_delta.ago)
        message.update_column(:created_at, (before_delta + 1).ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end

      it "user is not a donor (has no offers)" do
        Offer.update_all(created_by_id: nil)
        donor.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end

      it "donor's offer is draft" do
        Offer.update_all(state: 'draft')
        donor.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end

      it "donor's offer is closed" do
        Offer.update_all(state: 'closed')
        donor.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end

      it "donor's offer reviewed by reviewer" do
        msg3 = create(:message, offer: offer, sender: reviewer)
        reviewer.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end

      it "reviewers own active offer reviewed by him" do
        msg3 = create(:message, offer: reviewer_offer, sender: reviewer)
        reviewer.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end

      it 'donor has order unread messages' do 
        charity.update_column(:sms_reminder_sent_at, before_delta.ago)
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end

      it 'charity user who is also donor has no unread messages on the offer but on order' do
        msg4 = create(:message, offer: charity_offer, sender: reviewer)
        charity.update_column(:sms_reminder_sent_at, before_delta.ago) 
        charity.offers.first.subscriptions.unread.first.update_column(:state, 'read')
        expect(subject.send(:user_candidates_for_reminder).to_a).to eql([])
      end
    end
  end

  context "generate" do
    let(:time) { Time.zone.now }
    before(:each) do
      allow(subject).to receive(:user_candidates_for_reminder).and_return([donor])
      allow(Time).to receive(:now).and_return(time)
    end
    it "sends SMS reminders" do
      expect(subject).to receive(:send_sms_reminder).with(donor)
      subject.generate
    end
    it "updates sms_reminder_sent_at" do
      expect(donor).to receive(:update).with(sms_reminder_sent_at: time)
      subject.generate
    end
  end

  context "send_sms_reminder" do
    let(:sms_url) { "#{Rails.application.secrets.base_urls['app']}/offers" }
    let(:ts)      { TwilioService.new(build :user) }
    it "should call TwilioService with offer url in SMS body" do
      expect(TwilioService).to receive(:new).and_return(ts)
      expect(ts).to receive(:send_unread_message_reminder).with(sms_url)
      subject.send(:send_sms_reminder, donor)
    end
  end

end
