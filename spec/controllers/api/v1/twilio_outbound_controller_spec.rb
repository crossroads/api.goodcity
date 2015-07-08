require 'rails_helper'

RSpec.describe Api::V1::TwilioOutboundController, type: :controller do

  let(:user) { create :user }
  let(:basic_outbound_call_params) { {
    "AccountSid"     => ENV['TWILIO_ACCOUNT_SID'],
    "ApplicationSid" => ENV['TWILIO_CALL_APP_SID'],
    "Direction"      => "inbound",
    "ApiVersion"     => "2010-04-01",
    "Caller"         => "client:Anonymous",
    "CallSid"        => "CA7a9b9a9a6a113e45091c6482ebcf38b8",
    "From"           => "client:Anonymous"
  } }

  describe "generate_call_token" do
    let(:subject) { JSON.parse(response.body) }

    it "will generate Twilio Ougoing Call Capability Token", :show_in_doc do
      get :generate_call_token
      expect(response.status).to eq(200)
      expect(subject.keys).to eq(["token"])
      expect(subject["token"]).to be_present
    end
  end

  describe "connect_call" do
    let(:params) { basic_outbound_call_params.merge({
      "CallStatus"   => "ringing",
      "phone_number" => "9#148#+85251111111"
    }) }

    it "will generate response for twilio when Admin calling Donor's number", :show_in_doc do
      post :connect_call, params
      expect(response.status).to eq(200)
      expect(response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Dial callerId=\"+163456799\" action=\"/api/v1/twilio_outbound/completed_call\"><Number>+85251111111</Number></Dial></Response>")
    end
  end

  describe "completed_call" do
    let(:params) { basic_outbound_call_params.merge({
      "CallStatus"       => "in-progress",
      "DialCallSid"      => "CAf6de0c98d9d697b29ec60797f9e76ac2",
      "DialCallStatus"   => "completed",
      "DialCallDuration" => "30"
    }) }

    let(:failed_call_params) {
      params.merge({"DialCallStatus" => "no-answer"})
    }

    before {
      allow_any_instance_of(Api::V1::TwilioOutboundController).to receive_message_chain(:child_call, :to).and_return(user.mobile)
    }

    it "will generate response for twilio when Admin-Donor call is completed", :show_in_doc do
      post :completed_call, params
      expect(response.status).to eq(200)
      expect(response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Hangup/></Response>")
    end

    it "will generate response for twilio when Donor is not-answering or busy or call-fails", :show_in_doc do
      post :completed_call, failed_call_params
      expect(response.status).to eq(200)
      expect(response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Say>Couldn't reach #{user.full_name} try again soon. Goodbye.</Say><Hangup/></Response>")
    end
  end

  describe "call_status" do
    let(:params) { basic_outbound_call_params.merge({
      "CallStatus"     => "completed",
      "Duration"       => "1",
      "CallDuration"   => "17",
      "Timestamp"      => "Mon, 06 Jul 2015 11:36:41 +0000",
      "CallbackSource" => "call-progress-events",
      "SequenceNumber" => "0"
    }) }

    before {
      allow_any_instance_of(Api::V1::TwilioOutboundController).to receive_message_chain(:child_call, :to).and_return(user.mobile)
      allow_any_instance_of(Api::V1::TwilioOutboundController).to receive_message_chain(:child_call, :status).and_return("completed")
    }

    it "called from Twilio when outbound call completed", :show_in_doc do
      post :call_status, params
      expect(response.status).to eq(200)
      expect(response.body).to eq("{}")
    end
  end
end
