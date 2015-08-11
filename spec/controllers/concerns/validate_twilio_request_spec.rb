require 'rails_helper'

class TwilioFakeController < ActionController::Base
  include ValidateTwilioRequest

  before_action :validate_twilio_request
end

describe TwilioFakeController do

  let(:validator) {
    Twilio::Util::RequestValidator.new ENV['TWILIO_AUTH_TOKEN']
  }

  before { expect(Twilio::Util::RequestValidator).to receive(:new).
    and_return(validator) }

  it "should successfully validate a good token" do
    expect(validator).to receive(:validate).and_return(true)
    subject.send(:validate_twilio_request)
  end

  it "should throw unauthorized error if token validation fails" do
    expect(validator).to receive(:validate).and_return(false)
    expect{
      subject.send(:validate_twilio_request)
    }.to raise_error(ValidateTwilioRequest::TwilioAuthenticationError)
  end
end
