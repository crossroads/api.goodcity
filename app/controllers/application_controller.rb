class ApplicationController < ActionController::API
  include CanCan::ControllerAdditions
  before_filter :validate_pin

  private
    def current_user
      warden.user
    end

    helper_method :current_user

  def warden
    env["warden"]
  end

  #TODO:: Yet to add ActiveModel_OTP logic here
  def validate_pin
    user = warden.authenticate! :pin
    puts "#{user? ? user : "failed"}"
  end
end

