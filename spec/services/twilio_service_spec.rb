require 'rails_helper'

describe TwilioService do

  let(:mobile) { generate(:mobile) }
  let(:user)   { create :user, mobile: mobile }
  let(:twilio) { TwilioService.new(user) }

  context "initialize" do
    it do
      expect(twilio.user).to equal(user)
    end
    it "without arguments" do
      expect{TwilioService.new}.to raise_error(ArgumentError)
    end
  end

  describe "sms_verification_pin" do
    let(:otp_code) { "123456" }

    before {
      I18n.locale = :en
    }

    context "based on app_name" do
      before(:each) do
        allow(twilio).to receive(:send_to_twilio?).and_return(true)
        allow(user).to receive_message_chain(:most_recent_token, :otp_code).and_return(otp_code)
        body = "Single-use pin is #{otp_code}. GoodCity.HK welcomes you! Enjoy donating\nyour quality goods. (If you didn't request this message, please ignore)\n"
        expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
      end

      it "should send the SMS via Twilio for Donor App"  do
        twilio.sms_verification_pin(DONOR_APP)
      end

      it "should send the SMS via Twilio for Stock App"  do
        twilio.sms_verification_pin(ADMIN_APP)
      end

      it "should send the SMS via Twilio for Admin App"  do
        twilio.sms_verification_pin(STOCK_APP)
      end
    end

    context "based on app_name" do
      it "should send the SMS via Twilio for Browse App"  do
        allow(twilio).to receive(:send_to_twilio?).and_return(true)
        allow(user).to receive_message_chain(:most_recent_token, :otp_code).and_return(otp_code)
        body = "Single-use pin is #{otp_code}. GoodCity.HK welcomes you! Enjoy browsing quality goods.(If you didn't request this message, please ignore)\n"
        expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
        twilio.sms_verification_pin(BROWSE_APP)
      end
    end
  end

  context "order_confirmed_sms_to_charity" do
    let(:charity) { build(:user, :charity) }
    let(:order) { build(:order, created_by: charity) }

    it "sends order submitted acknowledgement to charity who submitted order" do
      allow(twilio).to receive(:send_to_twilio?).and_return(true)
      body = "Thank you for placing order #{order.code} on GoodCity. Our team will be in touch with you soon.\n"
      expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
      twilio.order_confirmed_sms_to_charity(order)
    end
  end

  context "order_submitted_sms_to_order_fulfilment_users" do
    let(:order_fulfilment_user) { build(:user, :order_fulfilment) }
    let(:charity) { build(:user, :charity) }
    let(:order) { build(:order, created_by: charity, submitted_by: charity) }

    it "sends order submitted alert to order_fulfilment_user" do
      allow(twilio).to receive(:send_to_twilio?).and_return(true)
      body = "#{charity.full_name} from #{order.organisation.name_en} has just placed an order #{order.code} on GoodCity.\n"
      expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
      twilio.order_submitted_sms_to_order_fulfilment_users(order)
    end
  end

  context "send_unread_message_reminder" do
    let(:donor) { create(:user, first_name: "John", last_name: "Lowe") }
    let(:url) { "#{Rails.application.secrets.base_urls['app']}/offers" }

    it "sends unread messages sms to donor " do
      body = "You've got notifications in GoodCity, please check the latest updates. #{url}."
      expect(twilio).to receive(:send_to_twilio?).and_return(true)
      expect(twilio).to receive(:unread_message_reminder).and_return( body )
      expect(TwilioJob).to receive(:perform_later).with(to: mobile, body: body)
      twilio.send_unread_message_reminder(url)
    end
  end

  context "send" do
    let(:options) { {body: "This is the SMS body"} }
    subject{ TwilioService.new(user) }
    it "should send message to Twilio" do
      expect(subject).to receive(:send_to_twilio?).and_return(true)
      sms_options = {to: user.mobile}.merge(options)
      expect(TwilioJob).to receive(:perform_later).with(sms_options)
      subject.send(:send_sms, options)
    end
    it "should send staging messages to Slack" do
      expect(subject).to receive(:send_to_twilio?).and_return(false)
      expect(TwilioJob).to_not receive(:perform_later)
      channel = ENV['SLACK_PIN_CHANNEL']
      message = "SlackSMS (to: #{user.mobile}, id: #{user.id}, full_name: #{user.full_name}) #{options[:body]}"
      expect(SlackMessageJob).to receive(:perform_later).with(message, channel)
      subject.send(:send_sms, options)
    end
  end

  # Be VERY careful here. Only stub prod env at last possible moment.
  # Create everything first to avoid hazardous AR callbacks in production env.
  context "send_to_twilio?" do
    it "should return true if production" do
      ts = TwilioService.new(user)
      expect(Rails).to receive_message_chain('env.production?').and_return(true)
      expect(ts.send(:send_to_twilio?)).to eql(true)
    end
    it "should return false if not production" do
      ts = TwilioService.new(user)
      expect(Rails).to receive_message_chain('env.production?').and_return(false)
      expect(ts.send(:send_to_twilio?)).to eql(false)
    end
  end

end
