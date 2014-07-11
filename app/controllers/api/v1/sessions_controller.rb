class SessionsController < Api::V1::ApiController

  def new
    render json: warden.message.to_json if warden.message.present?
  end

  def create
    debugger
    user = warden.authenticate!
    render json: user.to_json

  end

  def  destroy
    warden.logout
    render json: "Your are logged out".to_json
  end
end
