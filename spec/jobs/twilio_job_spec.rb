require "rails_helper"

describe TwilioJob, :type => :job do

  let(:options) { { to: generate(:mobile), body: "This is a test", from: generate(:mobile), risk_check: "disable" } }
  let(:twilio_client) { double(:twilio_client) }
  let(:system_phone_number) { '1234567890' }

  context "send_to_twilio?" do
    it "returns false if no 'to' number" do
      job = TwilioJob.new
      expect(job.send(:send_to_twilio?, { to: nil, body: "test" })).to be_falsey
    end
    it "returns false if not production environment" do
      job = TwilioJob.new
      allow(Rails.env).to receive(:production?).and_return(false)
      expect(job.send(:send_to_twilio?, { to: generate(:mobile), body: "test" })).to be_falsey
    end
    it "returns false if 'to' number is our own Twilio number" do
      job = TwilioJob.new
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(Rails.application.secrets).to receive(:twilio).and_return({ phone_number: system_phone_number })
      expect(job.send(:send_to_twilio?, { to: "+#{system_phone_number}", body: "test" })).to be_falsey
    end
    it "returns true if 'to' number is present, in production, and not our own number" do
      job = TwilioJob.new
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(Rails.application.secrets).to receive(:twilio).and_return({ phone_number: system_phone_number })
      expect(job.send(:send_to_twilio?, { to: "+#{system_phone_number.reverse}", body: "test" })).to be_truthy
    end
  end

  context "twilio_from" do
    it "returns phone number with '+' prefix if not present" do
      job = TwilioJob.new
      allow(Rails.application.secrets).to receive(:twilio).and_return({ phone_number: '1234567890' })
      expect(job.send(:twilio_from)).to eq('+1234567890')
    end
    it "returns phone number with '+' prefix if is already present" do
      job = TwilioJob.new
      allow(Rails.application.secrets).to receive(:twilio).and_return({ phone_number: '+1234567890' })
      expect(job.send(:twilio_from)).to eq('+1234567890')
    end
  end

  context "production environment" do
    before do
      allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
      allow_any_instance_of(TwilioJob).to receive(:send_to_twilio?).and_return(true)
    end
  
    it "should call twilio SDK with options" do
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
