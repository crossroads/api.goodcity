module Api
  module V1
    class ApiController < ApplicationController
      skip_before_action :validate_token, only: [:error]

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from CanCan::AccessDenied, with: :access_denied
      rescue_from Apipie::ParamInvalid, with: :invalid_params
      rescue_from Apipie::ParamMissing, with: :invalid_params

      def serializer_for(object)
        "Api::V1::#{object.class}Serializer".safe_constantize
      end

      def save_and_render_object(object)
        if object.save
          render json: object, serializer: serializer_for(object), status: 201
        else
          render json: object.errors, status: 422
        end
      end

      def save_and_render_object_with_errors(object)
        if object.save
          render json: object, serializer: serializer_for(object), status: 201
        else
          render_error(object.errors.full_messages.join(". "))
        end
      end

      def update_and_render_object_with_errors(object)
        if object.valid? && object.save
          render json: object, serializer: serializer_for(object)
        else
          render_error(object.errors.full_messages.join(". "))
        end
      end

      def render_error(error_message, code: 422)
        errors = { message: error_message, status: code }
        render json: { errors: [errors] }, status: code
      end

      def render_objects_with_cache(object, pid)
        pid = [pid].flatten.compact # catch 1 or [1]
        if pid.blank?
          render json: object.model.cached_json
        else
          object = object.where(id: pid.split(",").flatten.uniq)
          serializer = "Api::V1::#{object.base_class}Serializer".safe_constantize
          render json: object, each_serializer: serializer
        end
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

      def array_param(key)
        params.fetch(key, "").strip.split(",")
      end

      def bool_param(key, default)
        return default if params[key].nil?
        params[key].to_s == "true"
      end

      def time_epoch_param(key)
        timestamp = params.fetch(key, nil)
        return timestamp ? Time.at(Integer(timestamp) / 1000).in_time_zone : nil
      end

      private

      def access_denied
        throw(:warden, { status: 403, message: I18n.t("warden.unauthorized") }) if request.format.json?
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
end
