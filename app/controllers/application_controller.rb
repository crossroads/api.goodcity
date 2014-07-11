class ApplicationController < ActionController::API
  include CanCan::ControllerAdditions
  # before_action :validate_pin
  helper_method :current_user


  #TODO:: Yet to add ActiveModel_OTP logic here
  def validate_pin
    user = warden.authenticate! :pin
    puts "#{user? ? user : "failed"}"
  end

  def warden
    env["warden"]
  end

  private
    def current_user
      warden.user
    end

end

