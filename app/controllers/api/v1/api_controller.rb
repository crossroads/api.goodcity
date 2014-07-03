module Api::V1
  class ApiController < ApplicationController

    #respond_to :json
    rescue_from ActiveRecord::RecordNotFound, :with => :not_found

    private

    def not_found
      render :json => {}, :status => :not_found
    end

  end
end
