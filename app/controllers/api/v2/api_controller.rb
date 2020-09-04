module Api
  module V2
    class ApiController < ApplicationController
      # ------------------------
      # API V2 Base Controller
      # ------------------------

      skip_before_action :validate_token, only: [:error]

      rescue_from ActiveRecord::RecordInvalid, with: :invalid_params
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from CanCan::AccessDenied, with: :access_denied
      rescue_from Apipie::ParamInvalid, with: :invalid_params
      rescue_from Apipie::ParamMissing, with: :invalid_params
      rescue_from Goodcity::BaseError, with: :render_goodcity_error

      def current_ability
        @current_ability ||= Api::V2::Ability.new(current_user, role: active_role)
      end

      def active_role
        @active_role ||= begin
          allowed_roles = current_user&.roles || []
          role_name     = request.headers["X-GOODCITY-ROLE"]

          if role_name.blank?
            current_user&.top_role
          else
            role = allowed_roles.find { |r| r.snake_name == role_name }
            raise Goodcity::AccessDeniedError unless role.present?
            role
          end
        end
      end

      # ------------------------
      # Helpers
      # ------------------------

      def render_error(error_message, code: 422)
        render_goodcity_error Goodcity::BaseError.new(error_message, status: code)
      end

      # nil.to_i = 0
      def page
        @page = params["page"].to_i
        @page.zero? ? 1 : @page
      end

      # max limit is 50, default is 25
      def per_page
        @per_page = params["per_page"].to_i
        return DEFAULT_SEARCH_COUNT if @per_page < 1
        return MAX_SEARCH_COUNT if @per_page > MAX_SEARCH_COUNT
        @per_page
      end

      private

      # ------------------------
      # Error handlers
      # ------------------------

      def access_denied
        render_goodcity_error Goodcity::AccessDeniedError.new
      end

      def invalid_params(e)
        render_goodcity_error Goodcity::InvalidParamsError.with_text(e&.message)
      end

      def not_found(e)
        render_goodcity_error Goodcity::NotFoundError.with_text(e&.message)
      end

      def render_goodcity_error(e)
        render json: e.as_json, status: e.status
      end
    end
  end
end
