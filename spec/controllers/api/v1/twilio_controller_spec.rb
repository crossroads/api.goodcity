require 'rails_helper'

RSpec.describe Api::V1::TwilioController, type: :controller do

  let(:user) { create :user }
  let(:basic_call_params) { {
    "AccountSid"     => ENV['TWILIO_ACCOUNT_SID'],
    "Direction"      => "inbound",
    "ApiVersion"     => "2010-04-01",
    "CallSid"        => "CA7a9b9a9a6a113e45091c6482ebcf38b8",
    "From"           => user.mobile,
    "Caller"         => user.mobile,
    "To"             => ENV['TWILIO_VOICE_NUMBER'],
    "Called"         => ENV['TWILIO_VOICE_NUMBER']
  } }

  describe "hold_music" do
    let(:hold_music_path) { "app/assets/audio/30_sec_hold_music.mp3" }

    it "will return mp3 file played when user is waiting in queue" do
      get :hold_music
      expect(response.status).to eq(200)
      expect(response.stream.to_path).to eq(hold_music_path)
    end
  end

  describe "accept_call" do
    let(:reviewer) { create(:user, :reviewer) }
    let(:offer) { create :offer, :reviewed, created_by: user }
    before { create :version, item_type: 'Offer', item_id: offer.id, whodunnit: user.id.to_s }
    it "will return empty response", :show_in_doc do
      allow_any_instance_of(Api::V1::TwilioController).to receive(:activity_sid)
      allow_any_instance_of(Api::V1::TwilioController).to receive_message_chain(:offline_worker, :update)

      get :accept_call, { donor_id: user.id, mobile: reviewer.mobile }
      expect(response.status).to eq(200)
      expect(response.body).to eq("{}")
    end
  end

  describe "call_fallback" do
    let(:parameters) { basic_call_params.merge({
      "ErrorUrl"   => "http://api-staging.goodcity.hk/api/v1/twilio/voice",
      "CallStatus" => "ringing",
      "ErrorCode"  => "11200"
    }) }

    it "will return response to Twilio on call-failure", :show_in_doc do
      expect(Airbrake).to receive(:notify)

      post :call_fallback, parameters
      expect(response.status).to eq(200)
      expect(response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Say>Unfortunately there is some issue with connecting to Goodcity. Please try again after some time. Thank you.</Say><Hangup/></Response>")
    end
  end

  describe "call_summary" do
    let(:parameters) { basic_call_params.merge({
      "CallStatus"   => "completed",
      "Timestamp"    => Time.now.to_s,
      "CallDuration" => "66"
    }) }

    it "will return empty response", :show_in_doc do
      allow_any_instance_of(Api::V1::TwilioController).to receive_message_chain(:activity_sid)
      allow_any_instance_of(Api::V1::TwilioController).to receive_message_chain(:idle_worker, :update)

      post :call_summary, parameters
      expect(response.status).to eq(200)
      expect(response.body).to eq("{}")
    end
  end

  describe "voice" do
    let(:parameters) { basic_call_params.merge({ "CallStatus"=>"ringing"}) }

    context "Inactive Donor" do
      it "will return response to Twilio", :show_in_doc do
        post :voice, parameters
        expect(response.status).to eq(200)
        expect(response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Dial><Number>+85222729345</Number></Dial></Response>")
      end
    end

    context "Active Donor" do
      it "will return response to Twilio", :show_in_doc do
        expect(User).to receive(:inactive?).with(user.mobile).and_return([false, user])

        post :voice, parameters
        expect(response.status).to eq(200)
        expect(response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Enqueue workflowSid=\"#{ENV['TWILIO_WORKFLOW_SID']}\" waitUrl=\"/api/v1/hold_gc_donor\" waitUrlMethod=\"post\"><TaskAttributes>{\"selected_language\":\"en\",\"user_id\":#{user.id}}</TaskAttributes></Enqueue><Gather numDigits=\"1\" timeout=\"3\" action=\"/api/v1/accept_callback\"><Say>Unfortunately none of our staff are able to take your call at the moment.</Say><Say>You can request a call-back without leaving a message by pressing 1.</Say><Say>Otherwise, leave a message after the tone and our staff will get back to you as soon as possible. Thank you.</Say></Gather><Record maxLength=\"60\" playBeep=\"true\" action=\"/api/v1/send_voicemail\"/></Response>")
      end
    end
  end

  describe "hold_gc_donor" do
    let(:parameters) { basic_call_params.merge({
      "QueueSid"         => "QU2f978538fcc71e13701f703a884ff392",
      "CallStatus"       => "ringing",
      "QueueTime"        => "0",
      "AvgQueueTime"     => "0",
      "QueuePosition"    => "1",
      "CurrentQueueSize" => "1",
    }) }

    before {
      allow_any_instance_of(Api::V1::TwilioController).to receive(:offline_worker).and_return(false)
    }

    context "Caller waiting in queue for less than 30 seconds" do
      it "will return response to Twilio", :show_in_doc do
        post :hold_gc_donor, parameters
        expect(response.status).to eq(200)
        expect(response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Say>Hello #{user.full_name},</Say><Say>Thank you for calling GoodCity.HK, operated by Crossroads Foundation. Please wait a moment while we try to connect you to one of our staff.</Say><Play>http://test.host/api/v1/twilio/hold_music</Play></Response>")
      end
    end

    context "Caller waiting in queue for more than 30 seconds" do
      let(:params) { parameters.merge({ "QueueTime" => "40" }) }

      it "will return response to Twilio", :show_in_doc do
        post :hold_gc_donor, params
        expect(response.status).to eq(200)
        expect(response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Leave/></Response>")
      end
    end
  end

  describe "accept_callback" do
    let(:parameters) { basic_call_params.merge({
      "CallStatus" => "in-progress",
      "Digits"     => "1",
      "msg"        => "Gather End",
    }) }

    it "will return response to Twilio when user press 1 key", :show_in_doc do
      post :accept_callback, parameters
      expect(response.status).to eq(200)
      expect(response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Say>Thank you, our staff will call you as soon as possible. Goodbye.</Say><Hangup/></Response>")
    end
  end

  describe "send_voicemail" do
    let(:parameters) { basic_call_params.merge({
       "CallStatus"   => "completed",
       "RecordingUrl" => "http://api.twilio.com/2010-04-01/Accounts/<account_sid>/Recordings/<recording_sid>",
       "Digits"       => "hangup",
       "RecordingDuration" => "19",
       "RecordingSid" => "<RecordingSid>"
    }) }

    it "will return response to Twilio when user press 1 key", :show_in_doc do
      post :send_voicemail, parameters
      expect(response.status).to eq(200)
      expect(response.body).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Say>Goodbye.</Say><Hangup/></Response>")
    end
  end

  describe "assignment" do
    let(:admin) { create :user, :supervisor }
    let(:parameters) { {
      "WorkspaceSid"=>ENV['TWILIO_WORKSPACE_SID'],
      "WorkflowSid"=>ENV['TWILIO_WORKFLOW_SID'],
      "ReservationSid"=>"WR6e4c4e79ce0a7411e0fad3f2c53db619",
      "TaskQueueSid"=>"WQ221f569e7835ac4a724ddbcf955857c6",
      "TaskSid"=>"WTbd83b25v3454v5bn5vb29e64abf299347e4",
      "WorkerSid"=>"WKb1f124b5v3nb5vnb35v7d346dfae20ef38",
      "TaskAge"=>"13",
      "TaskPriority"=>"1",
      "TaskAttributes"=> basic_call_params.merge({
        "user_id":17,
        "selected_language":"en",
        "call_status":"ringing"}).to_json,
      "WorkerAttributes"=>{
        "languages":["en"],
        "user_id": ""
      }.to_json
    } }

    it "will return response to Twilio", :show_in_doc do
      allow_any_instance_of(Api::V1::TwilioController).to receive_message_chain(:redis, :get).and_return(admin.mobile)
      allow_any_instance_of(Api::V1::TwilioController).to receive(:activity_sid)

      post :assignment, parameters, format: :json
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq({"instruction"=>"dequeue", "post_work_activity_sid"=>nil, "from"=>ENV['TWILIO_VOICE_NUMBER'], "to"=>admin.mobile})
    end
  end

end
