# frozen_string_literal: true

module Api::V1
  class OrganisationsController < Api::V1::ApiController
    load_and_authorize_resource :organisation, parent: false

    resource_description do
      short "list, show organisations"
      formats ["json"]
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :organisation do
      param :organisation, Hash, required: true do
        param :name_en, String, desc: 'English name', allow_nil: false
        param :name_zh_tw, String, desc: 'Chinese name', allow_nil: true
        param :description_en, String, desc: 'English description of the organisation', allow_nil: true
        param :description_zh_tw, String, desc: 'Chinese description of the organisation', allow_nil: true
        param :type, String, desc: 'Type of organisation'
        param :website, String, desc: 'Website detail', allow_nil: true
        param :registration, String, desc: 'Registration detail', allow_nil: true
        param :country_id, String, desc: 'Country identifier', allow_nil: true
        param :crm_account_id, String, desc: 'CRM Account Id', allow_nil: true
      end
    end

    api :POST, '/v1/organisation', 'Create Organisation'
    param_group :organisation

    def create
      if @organisation.save
        return render json: @organisation, include_orders_count: false, serializer: organisation_serializer
      end

      render json: { errors: @organisation.errors.full_messages }, status: 422
    end

    api :PUT, '/v1/organisation/1', 'Update Organisation'
    param_group :organisation

    def update
      @organisation.assign_attributes(organisation_params)
      if @organisation.save
        return render json: @organisation, include_orders_count: false, serializer: organisation_serializer
      end

      render json: { errors: @organisation.errors.full_messages }, status: 422
    end

    api :GET, '/v1/organisations', "List all organisations"
    description <<~DESC
      Either `ids[]`, or a fuzzy name search (`searchText`), paged with `page` / `per_page`. Optional filters narrow the
      search's matches; when at least one filter is sent, an empty `searchText` lists every organisation that passes
      them, ordered by English name (without a filter an empty term still returns nothing, as before). `ids[]` ignores
      the filters. `meta.total_count` is the number of matching organisations across all pages.
    DESC
    param :organisation_type_id, /\A(\d+|none)\z/, desc: 'Only this organisation type id, or `none` for organisations with no type'
    param :country_id, /\A(\d+|none)\z/, desc: 'Only this country id, or `none` for organisations with no country'
    param :has_orders, %w[true false], desc: '`true`: at least one order (any state); `false`: none'
    param :has_members, %w[true false], desc: '`true`: at least one pending or approved member; `false`: none'
    param :has_registration, %w[true false], desc: '`true`: a registration that is not blank; `false`: blank or missing'
    def index
      find_record_and_render_json(organisation_serializer, filters: organisation_filters)
    end

    api :GET, '/v1/organisations/1', "Details of a package"
    def show
      record = Api::V1::OrganisationSerializer.new(@organisation,
                                                   root: "organisations",
                                                   include_orders_count: true).as_json
      render json: record
    end

    api :GET, '/v1/organisations/names', "List all organisations names"
    def names
      find_record_and_render_json(organisation_name_serializer)
    end

    api :GET, '/v1/organisations/:id/orders', "List all orders associated with organisation"
    def orders
      organisation_orders = @organisation.orders
      orders = organisation_orders.page(page).per(per_page).order('id')
      meta = {
        total_pages: orders.total_pages,
        total_count: orders.size
      }
      render json: { meta: meta }.merge(
        serialized_orders(orders)
      )
    end

    private

    def organisation_params
      params.require(:organisation)
            .permit(:name_en, :name_zh_tw, :country_id,
                    :website, :organisation_type_id,
                    :registration, :description_en,
                    :description_zh_tw, :crm_account_id)
    end

    def organisation_serializer
      Api::V1::OrganisationSerializer
    end

    def organisation_name_serializer
      Api::V1::OrganisationNamesSerializer
    end

    def order_serializer
      Api::V1::OrderShallowSerializer
    end

    def serialized_orders(orders)
      ActiveModel::ArraySerializer.new(
        orders,
        each_serializer: order_serializer,
        root: "designations",
        include_orders_count: true
      ).as_json
    end

    # The index's optional filters, read into Organisation.filtered's keys. Only the params sent are present; apipie has
    # already refused a value outside its pattern (422), so a typo can never be ignored into "every organisation".
    def organisation_filters
      filters = {}
      %w[organisation_type_id country_id].each do |key|
        next if params[key].nil?

        filters[key.to_sym] = params[key] == 'none' ? :none : params[key].to_i
      end
      %w[has_orders has_members has_registration].each do |key|
        filters[key.to_sym] = params[key] == 'true' unless params[key].nil?
      end
      filters
    end

    def find_record_and_render_json(serializer, filters: {})
      if params['ids'].present?
        records = @organisations.where(id: params['ids'])
                                .page(params["page"])
                                .per(params["per_page"] || DEFAULT_SEARCH_COUNT)
      elsif filters.any? && params["searchText"].blank?
        # browse: no term, at least one filter — every organisation that passes, by English name
        records = @organisations.with_order.filtered(filters)
                                .order(Arel.sql('LOWER(organisations.name_en) ASC, organisations.id ASC'))
                                .page(params["page"])
                                .per(params["per_page"] || DEFAULT_SEARCH_COUNT)
      else
        records = @organisations.with_order.search(params["searchText"]).filtered(filters)
                                .page(params["page"])
                                .per(params["per_page"] || DEFAULT_SEARCH_COUNT)
      end
      data = ActiveModel::ArraySerializer.new(records,
                                              each_serializer: serializer,
                                              root: "organisations",
                                              include_orders_count: true).as_json
      render json: { "meta": { total_pages: records.total_pages, total_count: records.total_count, "search": params["searchText"] } }.merge(data)
    end
  end
end
