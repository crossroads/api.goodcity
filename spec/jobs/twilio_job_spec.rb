require "rails_helper"

describe TwilioJob, :type => :job do

  let(:options) { { to: generate(:mobile), body: "This is a test", from: generate(:mobile) } }
  let(:twilio_client) { double(:twilio_client) }

  context "production environment" do
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

  context "staging environment" do
    before do
      allow(Rails.env).to receive(:staging?).and_return(true)
      allow_any_instance_of(TwilioJob).to receive(:send_to_twilio?).and_return(false)
    end

    it "should send an email instead of an SMS" do
      expect(ActionMailer::Base).to receive(:mail).with(
        from: ENV['EMAIL_FROM'],
        to: ENV['EMAIL_FROM'],
        subject: "SMS to #{options[:to]}",
        body: options[:body]
      ).and_return(double(deliver: true))

      TwilioJob.new.perform(options)
    end
  end
end
