class ApplicationController < ActionController::API
  include CanCan::ControllerAdditions
  helper_method :current_user
  def warden
    env["warden"]
  end

  def unauthenticated
    render json: {token: ""}
  end

  private
    def current_user
      warden.user
    end

end

