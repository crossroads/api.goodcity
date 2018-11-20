require 'rails_helper'

describe TwilioService do

  let(:mobile) { generate(:mobile) }
  let(:user)   { build :user, mobile: mobile }
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

    context "based on app_name" do
      before(:each) do
        allow(twilio).to receive(:allowed_to_send?).and_return(true)
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
        allow(twilio).to receive(:allowed_to_send?).and_return(true)
        allow(user).to receive_message_chain(:most_recent_token, :otp_code).and_return(otp_code)
        body = "Single-use pin is #{otp_code}. GoodCity.HK welcomes you! Enjoy browsing quality goods.(If you didn't request this message, please ignore)\n"
        expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
        twilio.sms_verification_pin(BROWSE_APP)
      end
    end
  end

  context "new_offer_alert" do
    let(:donor) { build(:user, first_name: "John", last_name: "Lowe") }
    let(:offer) { build(:offer, created_by: donor) }

    it "sends new offer alert SMS via Twilio" do
      allow(twilio).to receive(:allowed_to_send?).and_return(true)
      body = "John Lowe submitted new offer."
      expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
      twilio.new_offer_alert(offer)
    end
  end

  context "order_confirmed_sms_to_charity" do
    let(:charity) { build(:user, :charity) }
    let(:order) { build(:order, created_by: charity) }

    it "sends order submitted acknowledgement to charity who submitted order" do
      allow(twilio).to receive(:allowed_to_send?).and_return(true)
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
      allow(twilio).to receive(:allowed_to_send?).and_return(true)
      body = "#{charity.full_name} from #{order.organisation.name_en} has just placed an order #{order.code} on GoodCity.\n"
      expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
      twilio.order_submitted_sms_to_order_fulfilment_users(order)
    end
  end

  context "send_unread_message_reminder" do
    let(:donor) { create(:user, first_name: "John", last_name: "Lowe") }
    let(:url) { "#{Rails.application.secrets.base_urls['app']}/offers" }

    it "sends order submitted alert to order_fulfilment_user" do
      body = "You've got notifications in GoodCity, please check the latest updates. #{url}."
      expect(twilio).to receive(:allowed_to_send?).and_return(true)
      expect(twilio).to receive(:unread_message_reminder).and_return( body )
      expect(TwilioJob).to receive(:perform_later).with(to: mobile, body: body)
      twilio.send_unread_message_reminder(url)
    end
  end
end
