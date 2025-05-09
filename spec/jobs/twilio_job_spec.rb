require "rails_helper"

describe TwilioJob, :type => :job do

  let(:options) { { to: generate(:mobile), body: "This is a test", from: generate(:mobile) } }
  let(:twilio_client) { double(:twilio_client) }

  before do
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow_any_instance_of(TwilioJob).to receive(:send_to_twilio?).and_return(true)
  end

  it "should call twilio with options" do
    # prevent Twilio from sending an actual SMS
    expect(twilio_client).to receive_message_chain(:messages, :create).with(options)
    TwilioJob.new.perform(options)
  end

end
