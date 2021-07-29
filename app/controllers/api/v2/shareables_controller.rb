module Api
  module V2
    class ShareablesController < Api::V2::ApiController
      load_and_authorize_resource :shareable, parent: false, except: [:resource_index, :resource_show]
      skip_before_action :validate_token, only: [:resource_index, :resource_show]
      skip_authorization_check only: [:resource_index, :resource_show]

      rescue_from PG::UniqueViolation, with: :raise_duplicate!

      SERIALIZER_ALLOWED_FIELDS = {
        :offers => %i[id state notes expires_at created_at submitted_at district_id public_notes public_notes_zh_tw],
        :packages => %i[id notes notes_zh_tw package_type_id grade donor_condition_id offer_id received_quantity length width height favourite_image_id saleable value_hk_dollar package_set_id],
        :images => %i[id favourite cloudinary_id angle imageable_type imageable_id]
      }.with_indifferent_access

      SERIALIZER_ALLOWED_RELATIONSHIPS = {
        :offers => [:packages, :images],
        :packages  => [:package_type, :images]
      }.with_indifferent_access

      ALLOWED_MODELS = [:offers, :packages]

      resource_description do
        short "Access publicly shared records"
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :shareable do
        param :resource_id, String, required: true, allow_nil: false, desc: "The resource id"
        param :resource_type, String, required: true, allow_nil: false, desc: "The resource type"
        param :notes, String, required: false, allow_nil: true, desc: "Staff notes"
        param :notes_zh_tw, String, required: false, allow_nil: true, desc: "Staff notes"
        param :allow_listing, [true, false, 'true', 'false'], allow_nil: true, default: false, desc: "Whether we allow this item to be publicly listed"
        param :expires_at, String, allow_nil: true, desc: "If set, adds an expiration to this shareable record"
        param :overwrite, [true, false, 'true', 'false'], allow_nil: true, desc: "If set, allows overwriting existing shareable records"
      end

      def_param_group :shareable_update do
        param :allow_listing, [true, false, 'true', 'false'], allow_nil: true, default: false, desc: "Whether we allow this item to be publicly listed"
        param :expires_at, String, allow_nil: true, desc: "If set, adds an expiration to this shareable record"
        param :notes, String, required: false, allow_nil: true, desc: "Staff notes"
        param :notes_zh_tw, String, required: false, allow_nil: true, desc: "Staff notes"
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

        render json: serialize_resource(records, {
          meta: pagination_meta,
          params: {
            format: [:public]
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
        record = find_shared_record!(params[:public_uid], model_klass)

        render json: serialize_resource(record, {
          params: {
            format: [:public]
          }
        });
      end

      api :GET, "/v2/shareables/:id", "Gets the shareable row by id"
      description <<-EOS
        Returns the shareable row

        ===Response status codes
        * 200 - sucess
        * 404 - not found
        * 403 - forbidden
        * 401 - unauthorized
      EOS
      def show
        render json: serialize_shareables(@shareable)
      end

      api :DELETE, "/v2/shareables/:id", "Deletes the shareable row by id"
      description <<-EOS
        Deletes the shareable row

        ===Response status codes
        * 200 - sucess
        * 404 - not found
        * 403 - forbidden
        * 401 - unauthorized
      EOS
      def destroy
        @shareable.destroy!
        render json: {}, status: 200
      end

      api :GET, "/v2/shareables", "Gets the shareables"
      description <<-EOS
      Gets the shareables

        ===Response status codes
        * 200 - success
        * 401 - unauthorized
      EOS
      def index
        records = paginate(@shareables)
        records = records.of_type(params[:resource_type])                      if params[:resource_type].present?
        records = records.where(resource_id: params[:resource_id].split(','))  if params[:resource_id].present?

        render json: serialize_shareables(records, {
          meta: pagination_meta
        })
      end

      api :POST, "/v2/shareables", "Creates a shareable row by id"
      description <<-EOS
        Creates a shareable row by id

        ===Response status codes
        * 200 - success
        * 404 - forbidden
        * 422 - bad payload
        * 409 - already exists
      EOS
      param_group :shareable
      def create
        existing = Shareable.find_by(
          resource_id:    @shareable.resource_id,
          resource_type:  @shareable.resource_type,
        )

        if existing.present?
          raise Goodcity::DuplicateRecordError unless allow_overwrite?
          existing.destroy!
        end

        @shareable.assign_attributes(shareable_params)
        @shareable.created_by = current_user

        if  @shareable.save
          render json: serialize_shareables( @shareable), status: 201
        else
          invalid_params @shareable.errors.full_messages.first
        end
      end

      api :PUT, "/v2/shareables/:id", "Updates a shareable row by id"
      description <<-EOS
        Updates a shareable row by id

        ===Response status codes
        * 200 - success
        * 404 - forbidden
        * 422 - bad payload
        * 409 - already exists
      EOS
      param_group :shareable_update
      def update
        @shareable.assign_attributes(shareable_update_params)

        if  @shareable.save
          render json: serialize_shareables(@shareable), status: 200
        else
          invalid_params @shareable.errors.full_messages.first
        end
      end

      api :DELETE, "/v2/shareables/unshare", "Unshares a set of record"
      description <<-EOS
        Unshares a set of record

        ===Response status codes
        * 200 - success
        * 404 - forbidden
        * 422 - bad payload
        * 409 - already exists
      EOS
      def unshare
        raise Goodcity::MissingParamError.new('resource_type/resource_id') if (
          params[:resource_type].blank? || params[:resource_id].blank?
        )

        Shareable.unpublish_by_id(params[:resource_type], params[:resource_id].split(','))
        render json: {}, status: 200
      end

      private

      def shareable_params
        params.permit(:resource_id, :resource_type, :allow_listing, :expires_at, :notes, :notes_zh_tw)
      end

      def shareable_update_params
        params.permit(:allow_listing, :expires_at, :notes, :notes_zh_tw)
      end

      def allow_overwrite?
        params[:overwrite] == 'true'
      end

      def find_shared_record!(public_uid, klass)
        shareable = Shareable
          .non_expired
          .of_type(klass.name)
          .where(public_uid: public_uid)
          .first

        raise Goodcity::NotFoundError unless shareable.present? && shareable.resource.present?

        klass.find(shareable.resource_id)
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

      def serialize_resource(records, opts = {})
        model_serializer.new(records, {
          **opts,
          **serializer_options(params[:model])
        })
      end

      def serialize_shareables(shareable, opts = {})
        Api::V2::ShareableSerializer.new(shareable, opts)
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
