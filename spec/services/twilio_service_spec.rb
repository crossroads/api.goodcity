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

  context "sms_verification_pin" do

    before do
      allow(twilio).to receive(:allowed_to_send?).and_return(true)
      VCR.use_cassette "sms_otp_code" do
        # otp_code is 614979
        # otp_code_expiry is 2014-07-29 11:00:00 UTC
        @message = twilio.sms_verification_pin
      end
    end

    it "should send the SMS via Twilio" do
      expect(@message.body).to eql("Your pin is 614979 and will expire by 2014-07-29 11:00:00 UTC.")
    end

  end

end
