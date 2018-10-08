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

  context "sms_verification_pin" do
    let(:otp_code) { "123456" }
    it "should send the SMS via Twilio" do
      allow(twilio).to receive(:allowed_to_send?).and_return(true)
      allow(user).to receive_message_chain(:most_recent_token, :otp_code).and_return(otp_code)
      body = "Single-use pin is #{otp_code}. GoodCity.HK welcomes you! Enjoy donating\nyour quality goods. (If you didn't request this message, please ignore)\n"
      expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
      twilio.sms_verification_pin(DONOR_APP)
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
end
