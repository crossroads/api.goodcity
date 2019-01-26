require 'rails_helper'

describe SubscriptionsReminder do
  let(:user)          { create :user }
  let(:delta)         { SUBSCRIPTION_REMINDER_TIME_DELTA }
  let(:delta_plus_2)  { delta + 2.hours }
  let(:delta_minus_2) { delta - 2.hours }
  let(:time)          { Time.now }

  before(:each){ allow(Time).to receive(:now).and_return(time) }

  subject { SubscriptionsReminder.new }

  context "generate" do
    context "sends reminder when" do
      it "new unread message created in last X hours" do
        subscription = create(:subscription, user: user, state: 'unread')
        subject.generate
        expect(subscription.reload.sms_reminder_sent_at.to_s(:db)).to eq(time.to_s(:db))
        # TwilioService.new(User.find(user_id)).send_unread_message_reminder(sms_url)
        expect(TwilioService).to receive(:new)#.with(user).and_return(TwilioService.new(user))
      end
      it "2 new unread message created in last 4 hours only sends one reminder" do
      end
    end
  end

  context "doesn't send reminder when" do
    it "other reminders have been sent to same user within 4 hours"
    it "new message created in last 4 hours has already been read"
    it "reminder has already been sent for same message"
    it "it was written by the user themselves"
  end

end


# Send a message if
#   recipient is donor
#   a NEW message has been created in last 4 hours
#   AND it is still unread
#   AND no other reminders have been sent in last 4 hours

# Don't send message if
#   no new message has been created
#   OR new message has been created but it's not been at least 4 hours since the last reminder
#   OR the new message has been read already
#   OR it was written by the user

# Only ever alert for a message once
#   set sms_reminder_sent_at time on all messages when the reminder is sent

# If there is more than one new message, only send one SMS reminder.


#   context "generate" do
#     it "sends sms of unread messages if sms_reminder_sent_at is nil" do
#       subscription_reminder.generate
#       expect(subscription.reload.sms_reminder_sent_at.to_s(:db)).to eq(time.to_s(:db))
#     end

#     it "sends sms of unread messages if sms_reminder_sent_at gap time is more than 4 hours" do
#       subscription_reminder.generate
#       expect(subscription1.reload.sms_reminder_sent_at.to_s(:db)).to eq(time.to_s(:db))
#     end

#     it "do not sends sms of unread messages if sms_reminder_sent_at gap time is less than 4 hours" do
#       expect{ subscription_reminder.generate}.to_not change(Subscription.find(subscription2.id), :sms_reminder_sent_at)
#     end
#   end
