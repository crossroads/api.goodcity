module Api::V1
  class ApiController < ApplicationController

    skip_before_action :validate_token, only: [:error]

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from StandardError, with: :error_500

    private

    def not_found
      render json: {}, status: :not_found
    end

    def error_500(exception)
      Rails.logger.error(exception)
      Rails.logger.error(exception.backtrace)
      render json: {}, status: '500'
    end

  end
end
