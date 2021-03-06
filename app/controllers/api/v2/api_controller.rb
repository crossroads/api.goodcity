module Api
  module V2
    class ApiController < ApplicationController
      # ------------------------
      # API V2 Base Controller
      # ------------------------

      API_VERSION = 2

      resource_description do
        api_version "v2"
      end

      skip_before_action :validate_token, only: [:error]

      rescue_from ActiveRecord::RecordInvalid,  with: :invalid_params
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from CanCan::AccessDenied,         with: :access_denied
      rescue_from Apipie::ParamInvalid,         with: :invalid_params
      rescue_from Apipie::ParamMissing,         with: :invalid_params
      rescue_from Goodcity::BaseError,          with: :render_goodcity_error
      rescue_from PG::ForeignKeyViolation,      with: :foreign_key_violation

      def current_ability
        @current_ability ||= Api::V2::Ability.new(current_user, role: current_role)
      end

      def current_role
        @current_role ||= begin
          allowed_roles = current_user&.roles || []
          role_name     = request.headers["X-GOODCITY-ROLE"]

          return nil                    if role_name.blank?
          return Role.null_role         if role_name.eql?('user')
          
          role = allowed_roles.find { |r| r.snake_name == role_name }
          raise Goodcity::AccessDeniedError unless role.present?
          role
        end
      end

      # ------------------------
      # Helpers
      # ------------------------

      def serializer_options(model, opts = {})
        return {} unless params[:include].present?
        GoodcitySerializer.parse_include_paths(model, params[:include], opts)
      end

      def render_error(error_message, code: 422)
        render_goodcity_error Goodcity::BaseError.new(error_message, status: code)
      end

      # nil.to_i = 0
      def page
        _page = params["page"].to_i
        _page.zero? ? 1 : _page
      end

      # max limit is 50, default is 25
      def per_page
        _per_page = params["per_page"].to_i
        return DEFAULT_SEARCH_COUNT if _per_page.nil? || _per_page < 1
        return MAX_SEARCH_COUNT if _per_page > MAX_SEARCH_COUNT
        _per_page
      end

      def paginate(query)
        query.page(page).per(per_page)
      end

      def pagination_meta
        @pagination_meta ||= {
          page: page,
          per_page: per_page
        }
      end

      private

      # ------------------------
      # Error handlers
      # ------------------------

      def foreign_key_violation
        render_goodcity_error(
          request.method.eql?('DELETE') ?
            Goodcity::ForeignKeyDeletionError.new :
            Goodcity::ForeignKeyMismatchError.new
        )
      end

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
