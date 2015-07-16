module TwilioConfig
  extend ActiveSupport::Concern

  def set_header
    response.headers["Content-Type"] = "text/xml"
  end

  def render_twiml(response)
    render text: response.text
  end

  def set_json_header
    response.headers["Content-Type"] = "application/json"
  end

  def child_call
    @call ||= twilio_client.calls.list(parent_call_sid: params["CallSid"])[0]
  end

  private

  def activity_sid(friendly_name)
    task_router.activities.list(friendly_name: friendly_name).first.sid
  end

  def idle_worker
    task_router.workers.list(activity_name: "Idle").first
  end

  def mark_worker_offline
    idle_worker && idle_worker.update(activity_sid: activity_sid('Offline'))
  end

  def offline_worker
    task_router.workers.list(activity_name: "Offline").first
  end

  def task_router
    @client ||= Twilio::REST::TaskRouterClient.new(twilio_creds["account_sid"],
      twilio_creds["auth_token"], twilio_creds["workspace_sid"])
  end

  def twilio_client
    Twilio::REST::Client.new(twilio_creds["account_sid"],
      twilio_creds["auth_token"])
  end

  def twilio_outgoing_call_capability
    @capability ||= Twilio::Util::Capability.new(twilio_creds["account_sid"],
      twilio_creds["auth_token"])
    @capability.allow_client_outgoing(twilio_creds["call_app_sid"])
    @capability
  end

  def twilio_creds
    @twilio ||= Rails.application.secrets.twilio
  end

  def user(mobile = nil)
    @user ||= User.find_by_mobile(mobile || params["From"])
  end

  def voice_number
    number = twilio_creds["voice_number"].to_s
    number.prepend("+") unless number.starts_with?("+")
    number
  end
end
