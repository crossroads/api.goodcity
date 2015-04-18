require "rails_helper"

describe TwilioJob, :type => :job do

  let(:options) { { to: generate(:mobile), body: "This is a test", from: generate(:mobile) } }
  let(:twilio_client) { double(:twilio_client) }

  before do
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
  end

  it "should call twilio with options" do
    expect(twilio_client).to receive_message_chain(:account, :messages, :create).with(options)
    TwilioJob.new.perform(options)
  end

end
