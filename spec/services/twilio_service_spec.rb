require 'rails_helper'

describe TwilioService do

  let(:mobile) { generate(:mobile) }
  let(:user)   { create :user, mobile: mobile }
  let(:user_with_no_mobile) { create :user, mobile: nil, request_from_browse: true }
  let(:twilio) { TwilioService.new(user) }
  let(:twilio_with_no_mobile_user) {  TwilioService.new(user_with_no_mobile) }

  before { allow(twilio).to receive(:send_to_twilio?).and_return(true) }

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

    context 'Browse app' do
      %w[zh-tw en].map do |locale|
        context "for #{locale} language" do
          it "should send the SMS via Twilio in #{locale} language" do
            allow(user).to receive_message_chain(:most_recent_token, :otp_code).and_return(otp_code)
            body = I18n.t('twilio.browse_sms_verification_pin', pin: otp_code)
            expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
            twilio.sms_verification_pin(BROWSE_APP)
          end
        end
      end
    end
  end

  describe '#welcome_sms_text' do
    %w[zh-tw en].map do |locale|
      context "for #{locale} language" do
        let(:user) { create(:user, preferred_language: locale) }
        it "should send the SMS via Twilio in #{locale} language" do
          body = I18n.t('twilio.charity_user_welcome_sms', full_name: user.full_name, locale: locale)
          expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
          twilio.send_welcome_msg
        end
      end
    end
  end

  context "order_confirmed_sms_to_charity" do
    let(:user) { create(:user, :charity) }
    let(:order) { create(:order, created_by: user) }

    %w[zh-tw en].map do |locale|
      context "for #{locale} language" do
        let(:user) { create(:user, preferred_language: locale) }
        let(:order) { create(:order, created_by: user) }

        it "sends the SMS in #{locale} language" do
          body = I18n.t('twilio.new_order_submitted_sms_to_charity', code: order.code, locale: locale)
          expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
          twilio.order_confirmed_sms_to_charity(order)
        end
      end
    end

    it "sends order submitted acknowledgement to charity who submitted order" do
      body = "Thank you for placing order #{order.code} on GoodCity. Our team will be in touch with you soon.\n"
      expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
      twilio.order_confirmed_sms_to_charity(order)
    end

    context 'when the mobile number is nil for the user' do
      let(:user) { create(:user, mobile: nil, request_from_browse: true ) }
      let(:order_for_charity_without_mobile) { build(:order, created_by: user_with_no_mobile) }
      it "do not sends order submitted acknowledgement via sms to charity without mobile who submitted order" do
        expect(twilio_with_no_mobile_user).not_to receive(:send_to_twilio?)
        expect(TwilioJob).not_to receive(:perform_later)
        twilio.order_confirmed_sms_to_charity(order_for_charity_without_mobile)
      end
    end
  end

  ['zh-tw'].map do |locale|
    context "order_submitted_sms_to_order_fulfilment_users in #{locale} language" do
      let(:order_fulfilment_user) { build(:user, :order_fulfilment) }
      let(:charity) { build(:user, :charity, preferred_language: locale) }
      let(:order) { build(:order, created_by: charity, submitted_by: charity) }

      it "sends order submitted alert to order_fulfilment_user" do
        allow(twilio).to receive(:send_to_twilio?).and_return(true)
        body = "#{charity.full_name} from #{order.organisation.name_en} has just placed an order #{order.code} on GoodCity.\n"
        expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
        twilio.order_submitted_sms_to_order_fulfilment_users(order)
      end
    end
  end

  context "send_unread_message_reminder" do
    let(:url) { "#{Rails.application.secrets.base_urls[:app]}/offers" }

    %w[zh-tw en].map do |locale|
      let(:donor) { create(:user, preferred_language: locale) }

      context "for #{locale} language" do
        it "sends SMS in #{locale} language" do
          body = I18n.t('twilio.unread_message_sms', url: url)
          expect(twilio).to receive(:send_to_twilio?).and_return(true)
          expect(twilio).to receive(:unread_message_reminder).and_return( body )
          expect(TwilioJob).to receive(:perform_later).with(to: mobile, body: body)
          twilio.send_unread_message_reminder(url)
        end
      end
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

    it "should not send staging messages to Slack if mobile number is not present within twilio service" do
      twilio = TwilioService.new(user_with_no_mobile)
      expect(twilio).not_to receive(:send_to_twilio?)
      expect(TwilioJob).to_not receive(:perform_later)
      channel = ENV['SLACK_PIN_CHANNEL']
      message = "SlackSMS (to: #{user_with_no_mobile.mobile}, id: #{user_with_no_mobile.id}, full_name: #{user_with_no_mobile.full_name}) #{options[:body]}"
      expect(SlackMessageJob).not_to receive(:perform_later).with(message, channel)
      twilio.send(:send_sms, options)
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
