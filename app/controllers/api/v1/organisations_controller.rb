# frozen_string_literal: true

module Api::V1
  class OrganisationsController < Api::V1::ApiController
    BROWSE_MAX_PER_PAGE = 100

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
      Three kinds of request, paged with `page` / `per_page`:
      - `ids[]`: those organisations (the filters are ignored);
      - no `filter_…` param: the fuzzy name search (`searchText`, best matches first), exactly as before; an empty
        term returns nothing;
      - at least one `filter_…` param: the filtered listing. Every organisation that passes the filters, ordered by
        English name (then id), at most 100 a page. No fuzzy search: `filter_name` keeps the organisations whose
        English or Chinese name contains it (case-insensitive). A `searchText` sent with the filters means the same
        as `filter_name`; sending both is a 422.
      `meta.total_count` is the number of matching organisations across all pages.
    DESC
    # Every filter is named `filter_…`: no existing client (stock, admin, donor, browse, shared) sends a param of that
    # name, so the new behaviour can only be switched on by a client that asks for it.
    param :filter_organisation_type_id, /\A(\d+|none)\z/, desc: 'Only this organisation type id, or `none` for organisations with no type'
    param :filter_country_id, /\A(\d+|none)\z/, desc: 'Only this country id, or `none` for organisations with no country'
    param :filter_has_orders, %w[true false], desc: '`true`: at least one order (any state); `false`: none'
    param :filter_has_members, %w[true false], desc: '`true`: at least one pending or approved member; `false`: none'
    param :filter_has_registration, %w[true false], desc: '`true`: a registration that is not blank; `false`: blank or missing'
    param :filter_name, /\S/, desc: 'Only organisations whose English or Chinese name contains this text, ignoring case and the spaces around it (`%`, `_` and `\\` are plain characters). Not blank.'
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

    # The index's optional filters (`filter_<key>`), read into Organisation.filtered's keys. Only the params sent are present; apipie has
    # already refused a value outside its pattern (422), so a typo can never be ignored into "every organisation".
    def organisation_filters
      filters = {}
      %w[organisation_type_id country_id].each do |key|
        value = params["filter_#{key}"]
        next if value.nil?

        filters[key.to_sym] = value == 'none' ? :none : value.to_i
      end
      %w[has_orders has_members has_registration].each do |key|
        value = params["filter_#{key}"]
        filters[key.to_sym] = value == 'true' unless value.nil?
      end
      filters[:name] = params['filter_name'].strip unless params['filter_name'].nil?
      filters
    end

    def find_record_and_render_json(serializer, filters: {})
      if params['ids'].present?
        records = @organisations.where(id: params['ids'])
                                .page(params["page"])
                                .per(params["per_page"] || DEFAULT_SEARCH_COUNT)
      elsif filters.any?
        # The filtered listing: at least one filter_… param (no legacy client sends one). Never the fuzzy search: a name
        # is a "contains" match (filter_name; a searchText sent with the filters means the same, so a client that sends
        # its term as searchText still gets names that contain it, never fuzzy matches). Every organisation that passes,
        # by English name, then id. It can reach the whole table, so its page size is capped at BROWSE_MAX_PER_PAGE
        # (each row costs its orders and its members' sideloads); the legacy paths keep reading per_page as before.
        if params['searchText'].present?
          return render_error("Send the name as filter_name, not searchText, with the filter_ params") if filters.key?(:name)

          filters[:name] = params['searchText'].strip
        end
        records = @organisations.with_order.filtered(filters)
                                .order(Arel.sql('LOWER(organisations.name_en) ASC, organisations.id ASC'))
                                .page(params["page"])
                                .per([params["per_page"].to_i.nonzero? || DEFAULT_SEARCH_COUNT, BROWSE_MAX_PER_PAGE].min)
      else
        records = @organisations.with_order.search(params["searchText"])
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
