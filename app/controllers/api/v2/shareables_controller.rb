module Api
  module V2
    class ShareablesController < Api::V2::ApiController
      load_and_authorize_resource :shareables, parent: false, except: [:resource_index, :resource_show]
      skip_before_action :validate_token, only: [:resource_index, :resource_show]
      skip_authorization_check, only: [:resource_index, :resource_show]

      SERIALIZER_ALLOWED_FIELDS = {
        :offers => [:id, :state, :notes, :created_at],
        :items  => [:id, :donor_description, :state, :offer_id, :created_at, :package_type_id],
        :images => [:id, :favourite, :cloudinary_id, :angle, :imageable_type, :imageable_id]
      }.with_indifferent_access

      SERIALIZER_ALLOWED_RELATIONSHIPS = {
        :offers => [:items, :images], # We don't include the items, as some might not have been shared
        :items  => [:package_type, :offer, :images]
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

      api :GET, "/v2/shared/:model", "Lists publicly available models"
      description <<-EOS
        Returns the publicly available records of the specified model

        ===Response status codes
        * 200 - always succeeds with 200
        * 422 - bad or unsupported model
      EOS
      def resource_index
        records = model_klass.publicly_listed
        records = paginate(records)

        render json: serialize(records, {
          meta: pagination_meta,
          params: {
            include_public_uid: true
          }
        });
      end

      api :GET, "/v2/shared/:model/:public_uid", "Shows a publicly available model"
      description <<-EOS
        Returns the publicly available record of the specified model

        ===Response status codes
        * 200 - always succeeds with 200
        * 422 - bad or unsupported model
        * 404 - not found
      EOS
      def resource_show
        record = find_shared_record!(params[:public_uid], model_klass.name)
        
        render json: serialize(record, {
          params: {
            include_public_uid: true
          }
        });
      end

      api :GET, "/v2/shareables/:id", "Gets the shareable row by id"
      description <<-EOS
        Returns the shareable row

        ===Response status codes
        * 200 - always succeeds with 200
        * 404 - not found
        * 404 - forbidden
      EOS
      def show
        
      end

      private

      def find_shared_record!(public_uid, type)
        shareable = Shareable
          .non_expired
          .of_type(type)
          .where(public_uid: public_uid)
          .first

        raise Goodcity::NotFoundError unless shareable.present? && shareable.resource.present?

        shareable.resource
      end

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
        model_serializer.new(records, {
          **opts,
          **serializer_options(params[:model])
        })
      end

      def constantize(s)
        s.constantize
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
            fields[singularize(model)] << :public_uid
            fields
          end
        }
      end

      def raise_unsupported!        
        raise Goodcity::UnsupportedError.new(
          I18n.t('errors.unsupported_type', type: params[:model])
        )
      end
    end
  end
end
