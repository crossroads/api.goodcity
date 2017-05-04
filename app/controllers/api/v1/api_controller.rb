module Api::V1
  class ApiController < ApplicationController

    skip_before_action :validate_token, only: [:error]

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from CanCan::AccessDenied, with: :access_denied
    rescue_from Apipie::ParamInvalid, with: :invalid_params
    rescue_from Apipie::ParamMissing, with: :invalid_params


    def assign_object(data_object, params)
      data_object.attributes = params
      if contact.save
        render json: data_object, serializer: serializer, status: 201
      else
        render json: data_object.errors.to_json, status: 422
      end
    end

    private

    def access_denied
      throw(:warden, { status: 403, message: I18n.t("warden.unauthorized") } ) if request.format.json?
      render(file: "#{Rails.root}/public/403.#{I18n.locale}.html", status: 403, layout: false) if request.format.html?
    end

    def invalid_params(e)
      render json: { error: e.message }, status: 422
    end

    def not_found
      render json: {}, status: 404
    end
  end
end
