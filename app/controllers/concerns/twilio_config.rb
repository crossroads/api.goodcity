module TwilioConfig
  extend ActiveSupport::Concern

  def set_header
    response.headers["Content-Type"] = "text/xml"
  end

  def render_twiml(response)
    render plain: response.to_s
  end

  def set_json_header
    response.headers["Content-Type"] = "application/json"
  end

  def child_call
    @call ||= twilio_client.calls.list(parent_call_sid: params["CallSid"])[0]
  end

  private

  def activity_sid(friendly_name)
    twilio_client.taskrouter
                 .workspaces(twilio_creds["workspace_sid"])
                 .activities
                 .list(friendly_name: friendly_name)
                 .first.sid
  end

  def idle_worker
    twilio_client.taskrouter
                 .workspaces(twilio_creds["workspace_sid"])
                 .workers
                 .list(activity_name: "Idle")
                 .first
  end

  def mark_worker_offline
    idle_worker && idle_worker.update(activity_sid: activity_sid('Offline'))
  end

  def offline_worker
    twilio_client.taskrouter
                 .workspaces(twilio_creds["workspace_sid"])
                 .workers
                 .list(activity_name: "Offline")
                 .first
  end

  def twilio_client
    Twilio::REST::Client.new(twilio_creds["account_sid"],
      twilio_creds["auth_token"])
  end

  def twilio_outgoing_call_capability
    account_sid = twilio_creds["account_sid"]
    api_key = twilio_creds["api_key"]
    api_secret = twilio_creds["twilio_secret"]

    # Required for Voice
    outgoing_application_sid = twilio_creds["call_app_sid"]
    identity = 'user'

    # Create Voice grant for our token
    grant = Twilio::JWT::AccessToken::VoiceGrant.new
    grant.outgoing_application_sid = outgoing_application_sid

    # Optional: add to allow incoming calls
    grant.incoming_allow = true

    # Create an Access Token
    token = Twilio::JWT::AccessToken.new(
      account_sid,
      api_key,
      api_secret,
      [grant],
      identity: identity
    )

    # Generate the token
    token.to_jwt

  end

  def twilio_creds
    @twilio ||= Rails.application.secrets.twilio
  end

  def user(mobile = nil)
    @user = User.find_by(mobile: mobile.presence || params["From"])
  end

  def voice_number
    number = twilio_creds["voice_number"].to_s
    number.prepend("+") unless number.starts_with?("+")
    number
  end
end
