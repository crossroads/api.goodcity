module Api
  module V2
    class ShareablesController < Api::V2::ApiController
      skip_before_action :validate_token
      skip_authorization_check

      SERIALIZER_WHITELIST = {
        offers: [:id, :state, :notes, :created_at],
        items:  [:id, :donor_description, :state, :offer_id, :created_at, :package_type_id],
        images: '*'
      }

      resource_description do
        short "Access publicly shared records"
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, "/v2/shared/:model", "Lists publicly availabel models"
      description <<-EOS
        Returns the publicly available records of the specified model

        ===Response status codes
        * 200 - always succeeds with 200
        * 422 - bad or unsupported model
      EOS
      param :include, String, required: false, desc: "A comma separated list of the attributes/relationships to include in the response"
      def list
        render json: serialize(params[:model], model_klass.publicly_listed)
      end

      private

      def model_klass
        @model_klass ||= constantize(params[:model].classify)
      end

      def model_serializer
        @serializer_klass ||= constantize("Api::V2::#{model_klass}Serializer")
      end

      def serialize(records)
        model_serializer.new(serializer_options(:user, { whitelist: SERIALIZER_WHITELIST }))
      end

      def constantize(sig)
        sig.constantize
      rescue
        raise_unsupported!
      end

      def raise_unsupported!
        raise Goodcity::UnsupportedError.new(
          I18n.t('errors.unsupported_type', type: params[:model])
        )
      end
    end
  end
end
