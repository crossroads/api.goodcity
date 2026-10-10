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
      param :admin, String, desc: <<-DOC
        Send admin=true for the goods-types editor's list: { package_types: [ { id, code, name_en, name_zh_tw,
        other_terms_en, other_terms_zh_tw, department, location_id, subform, allow_package, allow_pieces,
        allow_box, allow_pallet, allow_requests, visible_in_selects, allow_expiry_date, package_category_ids,
        in_use, item_count, package_count, request_count } ] }. Every type, retired ones included, ordered
        by id. Not cached. Requires a signed-in user who can update package types (401 / 403 otherwise).
        Without admin=true the response is the legacy cached list, unchanged.
      DOC
      def index
        return admin_index if params[:admin].to_s == "true"
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

      api :DELETE, "/v1/package_types/:id", "Retire a package type (flags switched off, record kept), or delete a never-used one"
      param :hard, String, desc: <<-DOC
        Without it (the default) the type is RETIRED: visible_in_selects, allow_package, allow_box,
        allow_pallet, allow_pieces and allow_requests are switched off, the record is kept and existing
        stock keeps its type; reply 200 { package_type: <admin shape> }. Send hard=true to DELETE the
        record instead, allowed only for a type nothing has ever used (no items, packages,
        goodcity_requests or package_sets point at it): its containment rows on both sides
        (subpackage_types as parent and as child) and its category joins go with it; reply 200 {}.
        A used type answers 422 { errors: [{ message, status }] } and nothing changes.
      DOC
      def destroy
        return hard_destroy if params[:hard].to_s == "true"

        # Retire through the normal save path so callbacks run: paper_trail writes a version and
        # updated_at moves (the cached GET /package_types re-keys); the visible-only ?stock=true list
        # re-keys on its row count (CacheableJson), so the legacy apps stop offering the type.
        # validate: false so unusual legacy data (blank name, old-style code) never blocks a retire;
        # the admin-editor rules are context-only (on: :admin) and a plain save skips them anyway.
        @package_type.assign_attributes(
          visible_in_selects: false, allow_package: false, allow_box: false,
          allow_pallet: false, allow_pieces: false, allow_requests: false
        )
        @package_type.save(validate: false)
        render json: @package_type.reload, serializer: admin_serializer, root: "package_type"
      end

      api :POST, "/v1/package_types/:id/subpackage_types", "Allow another goods type inside this one (containment)"
      description <<-DOC
        Adds a subpackage_types row with this type as the parent. 201 { subpackage_type: { id,
        package_type_id, subpackage_type_id, is_default, child_code, child_name } }. 422
        { errors: [{ message, status }] } when the child is already allowed (one row per parent and
        child) or the child type does not exist. Every type already holds itself as its default
        content; that row is made by the server when the type is created.
      DOC
      param :id, String, required: true, desc: "Parent package type id"
      param :subpackage_type, Hash, required: true do
        param :subpackage_type_id, Integer, required: true, desc: "Child package type id"
        param :is_default, :boolean, desc: "Default content of the parent (default false)"
      end
      def add_subpackage_type
        attrs = params.require(:subpackage_type)
        child = PackageType.find_by(id: attrs[:subpackage_type_id])
        return render_error("There is no goods type #{attrs[:subpackage_type_id]}") unless child

        # A type that holds itself holds itself as its default content (what after_create makes), so a
        # self row added here (legacy types such as FWT have none) is always a default one.
        is_default = child.id == @package_type.id || boolean_param(attrs[:is_default])
        sub = nil
        refused = SubpackageType.transaction do
          # The lock serialises containment writes per parent: there is no unique index on
          # (package_type_id, subpackage_type_id), so two concurrent adds could otherwise both pass valid?.
          @package_type.lock!
          sub = @package_type.subpackage_types.new(child_package_type: child, is_default: is_default)
          next already_allowed(child) unless sub.valid?
          sub.save!
          rekey_cached_lists(@package_type.id)
          nil
        end
        return render_error(refused) if refused
        render json: sub, serializer: Api::V1::SubpackageTypeSerializer, root: "subpackage_type", status: 201
      end

      api :PATCH, "/v1/package_types/:id/subpackage_types/:child_id", "Mark an allowed child type as default content or not"
      description <<-DOC
        Also accepts PUT. 200 with the row. 404 when the child is not allowed in this type. 422 when
        switching off the type's own self row (child_id = id), or the parent's LAST default row: the stock
        app makes new stock of a type as its first default child, and admin review adds a package per
        default child, so a type is never left with no default.
      DOC
      param :id, String, required: true, desc: "Parent package type id"
      param :child_id, String, required: true, desc: "Child package type id"
      param :is_default, :boolean, required: true
      def set_subpackage_default
        sub = find_subpackage
        is_default = boolean_param(params[:is_default])
        refused = SubpackageType.transaction do
          @package_type.lock!
          sub.reload
          next "A goods type always holds itself as its default content; that can't be switched off" if self_row?(sub) && !is_default
          next last_default(sub, "switched off") if !is_default && last_default?(sub)
          sub.update!(is_default: is_default)
          rekey_cached_lists(@package_type.id)
          nil
        end
        return render_error(refused) if refused
        render json: sub, serializer: Api::V1::SubpackageTypeSerializer, root: "subpackage_type"
      end

      api :DELETE, "/v1/package_types/:id/subpackage_types/:child_id", "Stop allowing a child type inside this one"
      description <<-DOC
        200 {} once the row is gone. 404 when the child is not allowed in this type. 422 for the type's
        own self row (child_id = id), and for the parent's LAST default row (see the PATCH).
      DOC
      param :id, String, required: true, desc: "Parent package type id"
      param :child_id, String, required: true, desc: "Child package type id"
      def remove_subpackage_type
        sub = find_subpackage
        refused = SubpackageType.transaction do
          @package_type.lock!
          next "A goods type always holds itself as its default content; that can't be removed" if self_row?(sub)
          next last_default(sub, "removed") if last_default?(sub.reload)
          sub.destroy!
          rekey_cached_lists(@package_type.id)
          nil
        end
        return render_error(refused) if refused
        render json: {}
      end

      private

      # The cached legacy lists, GET /package_types and GET /package_types?stock=true, embed each type's
      # child codes (PackageTypeSerializer default_child_packages / other_child_packages) and are keyed
      # on MAX(updated_at) + row count of package_types (CacheableJson). A subpackage_types write moves
      # neither, so move the parents' updated_at. update_all: no callbacks and no paper_trail version
      # for a timestamp-only change. (A parent outside the visible scope is not in the ?stock=true body,
      # so that list needs no new key for it.)
      def rekey_cached_lists(*type_ids)
        ids = type_ids.flatten.compact.uniq
        PackageType.where(id: ids).update_all(updated_at: Time.current) if ids.any?
      end

      def find_subpackage
        @package_type.subpackage_types.includes(:child_package_type).find_by!(subpackage_type_id: params[:child_id])
      end

      def self_row?(sub)
        sub.subpackage_type_id == @package_type.id
      end

      def last_default?(sub)
        sub.is_default && !@package_type.subpackage_types.where(is_default: true).where.not(id: sub.id).exists?
      end

      def last_default(sub, verb)
        "#{sub.child_package_type.try(:code)} is the only default content of #{@package_type.code}, so it can't be #{verb}: " \
          "make another type default first"
      end

      def already_allowed(child)
        "#{child.code} is already allowed inside #{@package_type.code}"
      end

      def boolean_param(value)
        ActiveModel::Type::Boolean.new.cast(value) || false
      end

      # DELETE ?hard=true. Only a type nothing has ever used: its own containment rows (both sides)
      # and category joins are removed with it, then the record. Parents that listed it as a child
      # are re-keyed so the cached legacy lists drop its code. paper_trail keeps a destroy version
      # with the full record.
      def hard_destroy
        usage = @package_type.usage_counts
        if usage.values.any?(&:positive?)
          used = usage.select { |_, n| n.positive? }.map { |what, n| "#{n} #{what.to_s.tr('_', ' ')}" }.join(", ")
          return render_error("#{@package_type.code} is in use (#{used}); retire it instead")
        end

        id = @package_type.id
        # A parent whose ONLY default content is this type would be left with none (see set_subpackage_default).
        sole = SubpackageType.where(subpackage_type_id: id, is_default: true).where.not(package_type_id: id)
                             .where.not(package_type_id: SubpackageType.where(is_default: true).where.not(subpackage_type_id: id).select(:package_type_id))
                             .includes(:package_type).map { |s| s.package_type.code }
        if sole.any?
          return render_error("#{@package_type.code} is the only default content of #{sole.sort.join(', ')}; make another type default there first")
        end

        parent_ids = SubpackageType.where(subpackage_type_id: id).where.not(package_type_id: id).pluck(:package_type_id)
        PackageType.transaction do
          # destroy_all: each row's paper_trail version records what went.
          SubpackageType.where(package_type_id: id).or(SubpackageType.where(subpackage_type_id: id)).destroy_all
          # destroy_all (not delete_all): the join rows' touch: true re-keys the cached GET /package_categories.
          @package_type.package_categories_package_types.destroy_all
          @package_type.destroy!
          rekey_cached_lists(parent_ids)
        end
        render json: {}
      rescue ActiveRecord::InvalidForeignKey
        render_error("#{@package_type.code} is still referenced; retire it instead")
      end

      # The editor's list. index skips validate_token for the public legacy list, so this branch checks
      # the token itself. Usage counts and category ids are batched: one GROUP BY per usage table and
      # one pluck of the join table, whatever the number of types.
      def admin_index
        validate_token
        authorize! :update, PackageType
        category_ids = PackageCategoriesPackageType.order(:package_category_id)
                                                   .pluck(:package_type_id, :package_category_id)
                                                   .group_by(&:first)
                                                   .transform_values { |pairs| pairs.map(&:last) }
        rows = ActiveModel::ArraySerializer.new(
          PackageType.order(:id),
          each_serializer: Api::V1::PackageTypeAdminRowSerializer,
          root: "package_types",
          category_ids: category_ids,
          item_counts: Item.group(:package_type_id).count,
          package_counts: Package.group(:package_type_id).count,
          request_counts: GoodcityRequest.group(:package_type_id).count
        )
        render json: rows.as_json
      end

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
        ids = Array(params[:package_type][:package_category_ids]).reject(&:blank?).map(&:to_i)
        before_ids = @package_type.persisted? ? @package_type.package_category_ids : []
        @package_type.package_category_ids = ids
        # Removing through has_many :through deletes the join rows without callbacks, so the join
        # model's `belongs_to :package_category, touch: true` never fires for a removed category.
        # Touch those here so the cached GET /package_categories (package_type_codes) moves too.
        # (Added categories are touched by the join rows' own create callbacks.)
        removed = before_ids - ids
        PackageCategory.where(id: removed).touch_all if removed.any?
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
