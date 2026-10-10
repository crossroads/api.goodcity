module Api
  module V1
    class PackageTypesController < Api::V1::ApiController
      skip_before_action :validate_token, only: [:index]
      load_and_authorize_resource :package_type, parent: false

      resource_description do
        short "Get package types."
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 500, "Internal Server Error"
      end

      api :GET, "/v1/package_types", "get all package_types"
      def index
        return stock_codes if params['stock'].present?
        render json: @package_types.with_eager_load.cached_json
      end

      def stock_codes
        render json: @package_types.visible.with_eager_load
                                   .cached_json({ root: :codes })
      end

      def_param_group :package_type do
        param :package_type, Hash, required: true do
          param :code, String, desc: "Unique upper-case alphanumeric code"
          param :name_en, String
          param :name_zh_tw, String
          param :other_terms_en, String
          param :other_terms_zh_tw, String
          param :description_en, String
          param :description_zh_tw, String
          param :subform, String, desc: "'', medical, electrical, computer_accessory or computer"
          param :location_id, Integer, allow_nil: true
          param :department, String
          param :allow_package, [true, false]
          param :allow_pieces, [true, false]
          param :allow_box, [true, false]
          param :allow_pallet, [true, false]
          param :allow_requests, [true, false]
          param :visible_in_selects, [true, false]
          param :allow_expiry_date, [true, false]
          param :default_value_hk_dollar, :decimal, allow_nil: true
          param :customs_value_usd, :decimal, allow_nil: true
          param :length, Integer, allow_nil: true
          param :width, Integer, allow_nil: true
          param :height, Integer, allow_nil: true
          param :package_category_ids, Array, of: Integer, desc: "Declarative set of category ids"
        end
      end

      api :GET, "/v1/package_types/:id", "Get one package type with all editable fields"
      def show
        render json: @package_type, serializer: admin_serializer, root: "package_type"
      end

      api :POST, "/v1/package_types", "Create a package type (default subpackage is added automatically)"
      param_group :package_type
      def create
        PackageType.transaction do
          @package_type.assign_attributes(package_type_params)
          assign_categories
          save_admin(@package_type, status: 201) || raise(ActiveRecord::Rollback)
        end
      end

      api :PUT, "/v1/package_types/:id", "Update a package type"
      param_group :package_type
      def update
        PackageType.transaction do
          @package_type.assign_attributes(package_type_params)
          assign_categories
          save_admin(@package_type, status: 200) || raise(ActiveRecord::Rollback)
        end
      end

      api :DELETE, "/v1/package_types/:id", "Retire a package type (flags switched off, record kept)"
      def destroy
        @package_type.update_columns(
          visible_in_selects: false, allow_package: false, allow_box: false,
          allow_pallet: false, allow_pieces: false, allow_requests: false,
          updated_at: Time.current
        )
        Rails.cache.delete(PackageType.cache_key)
        render json: @package_type.reload, serializer: admin_serializer, root: "package_type"
      end

      private

      def save_admin(record, status:)
        if record.save(context: :admin)
          render json: record, serializer: admin_serializer, root: "package_type", status: status
          true
        else
          render json: record.errors, status: 422
          false
        end
      end

      # Category set is applied inside the action's transaction (not by the
      # CanCan loader) so a failed validation rolls the join rows back too.
      def assign_categories
        return unless params[:package_type].key?(:package_category_ids)
        ids = Array(params[:package_type][:package_category_ids]).reject(&:blank?)
        @package_type.package_category_ids = ids
      end

      def package_type_params
        params.require(:package_type).permit(
          :code, :subform, :location_id, :department,
          :name_en, :name_zh_tw, :other_terms_en, :other_terms_zh_tw,
          :description_en, :description_zh_tw,
          :allow_package, :allow_pieces, :allow_box, :allow_pallet,
          :allow_requests, :visible_in_selects, :allow_expiry_date,
          :default_value_hk_dollar, :customs_value_usd,
          :length, :width, :height,
        )
      end

      def admin_serializer
        Api::V1::PackageTypeAdminSerializer
      end

      def serializer
        Api::V1::PackageTypeSerializer
      end
    end
  end
end
