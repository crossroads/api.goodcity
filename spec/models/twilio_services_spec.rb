require 'rails_helper'

describe TwilioServices do
  describe "Twilio" do
    let!(:user) {create :user}
    it "should have user while initializing" do
      tw_user =TwilioServices.new(user)
      expect(tw_user.instance_values["user"]).to equal(user)
    end

    it "should throw an exception if there is no user" do
      expect {TwilioServices.new}.to raise_error(ArgumentError)
    end
  end
  describe "#sms_verification_pin" do
    it "send sms to the given mobile"
  end
end
