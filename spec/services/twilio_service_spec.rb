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
      twilio.sms_verification_pin
    end
  end

  context "new_offer_alert" do

    let(:donor) { build(:user, first_name: "John", last_name: "Lowe") }
    let(:offer) { build(:offer, created_by: donor) }

    it "sends new offer alert SMS via Twilio" do
      allow(twilio).to receive(:allowed_to_send?).and_return(true)
      base_url = "#{Rails.application.secrets.base_urls["admin"]}/offers/#{offer.id}/review_offer/items"
      body = "John Lowe submitted #{base_url}"
      expect(TwilioJob).to receive(:perform_later).with(to: user.mobile, body: body)
      twilio.new_offer_alert(offer)
    end

  end

end
