class ApplicationController < ActionController::API
  
  include CanCan::ControllerAdditions
  
  def current_user
    nil
  end
  
end
