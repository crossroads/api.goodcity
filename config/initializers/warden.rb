Rails.application.config.middleware.use Warden::Manager do |manager|
  manager.default_strategies :pin
  manager.failure_app = lambda { |env| SessionsController.action(:new).call(env) }
end

 # Setup Session Serialization
Warden::Manager.serialize_into_session do |user|
  user.id
end

Warden::Manager.serialize_from_session do |id|
  User.find(id)
end

# Strategies
Warden::Strategies.add(:pin) do
 def valid?
  params["token"] || params["pin"]
 end

 # TODO:: Yet to wrap up completedly with the methods of ActiveModel_otp
 def authenticate!
    unless params["token"].blank?
      user = User.auth_tokens.where("token = ? ", params["token"])
      if user && user.auth_tokens.authenticate_otp(params["pin"])
        success! user
      else
        fail! "error"
      end
    end
 end
end
