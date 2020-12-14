module Api
  module V2
    class ShareablesController < Api::V2::ApiController
      skip_before_action :validate_token
      skip_authorization_check

      SERIALIZER_ALLOWED_FIELDS = {
        :offers => [:id, :state, :notes, :created_at],
        :items  => [:id, :donor_description, :state, :offer_id, :created_at, :package_type_id]
      }.with_indifferent_access

      SERIALIZER_ALLOWED_RELATIONSHIPS = {
        :offers => [:items], # We don't include the items, as some might not have been shared
        :items  => [:package_types, :offers, :images]
      }.with_indifferent_access

      ALLOWED_MODELS = [:offers, :items]

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
        records = model_klass.publicly_listed
        records = paginate(records)
        render json: serialize(records, meta: pagination_meta);
      end

      private

      def model_klass
        @model_klass ||= begin
          model = constantize(params[:model].classify)
          raise_unsupported! unless model.methods.include?(:public_context)
          model.public_context
        end
      end

      def model_serializer
        @serializer_klass ||= constantize("Api::V2::#{model_klass.name}Serializer")
      end

      def serialize(records, opts = {})
        model_serializer.new(records, { **opts, **serializer_options(params[:model]) })
      end

      def constantize(sig)
        sig.constantize
      rescue
        raise_unsupported!
      end

      def singularize(s)
        s.to_s.singularize.to_sym
      end

      #
      # <Description>
      #
      # @override
      # @param [Symbol] model the model to retrieve the serialization options of
      #
      # @return [Hash] json serializer options
      #
      def serializer_options(model)
        model = model.downcase.to_sym
        
        raise_unsupported! unless model.in?(ALLOWED_MODELS)

        relations = SERIALIZER_ALLOWED_RELATIONSHIPS[model] || []

        {
          include: relations,
          fields: [*relations, model].reduce({}) do |fields, model|
            fields[singularize(model)] = SERIALIZER_ALLOWED_FIELDS[model] || []
            fields
          end
        }
      end

      def raise_unsupported!
        byebug
        raise Goodcity::UnsupportedError.new(
          I18n.t('errors.unsupported_type', type: params[:model])
        )
      end
    end
  end
end
