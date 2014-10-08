require 'rails_helper'

describe TwilioService do

  let(:user) { create :user }
  let(:twilio) { TwilioService.new(user) }

  context "initialize" do
    it do
      expect(twilio.user).to equal(user)
    end

    it "without user" do
      expect{TwilioService.new}.to raise_error(ArgumentError)
    end
  end

end
