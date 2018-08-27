module Api::V1
  class OrderSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :status, :created_at, :code, :detail_type, :id, :detail_id,
      :contact_id, :local_order_id, :organisation_id, :description, :activity,
      :country_name, :state, :purpose_description, :created_by_id, :item_ids,
      :gc_organisation_id, :processed_at, :processed_by_id, :cancelled_at, :cancelled_by_id,
      :process_completed_at, :process_completed_by_id, :closed_at, :closed_by_id, :dispatch_started_at,
      :dispatch_started_by_id, :submitted_at, :submitted_by_id

    has_one :created_by, serializer: UserProfileSerializer, root: :user
    has_one :stockit_contact, serializer: StockitContactSerializer
    has_one :stockit_organisation, serializer: StockitOrganisationSerializer, root: :organisation
    has_one :stockit_local_order, serializer: StockitLocalOrderSerializer, root: :local_order
    has_one :order_transport, serializer: OrderTransportSerializer
    has_one :organisation, serializer: OrganisationSerializer
    has_many :packages, serializer: StockitItemSerializer, root: :items
    has_many :cart_packages, serializer: BrowsePackageSerializer, root: :packages
    has_many :orders_packages, serializer: OrdersPackageSerializer
    has_many :orders_purposes, serializer: OrdersPurposeSerializer
    has_many :requests, serializer: RequestSerializer
    has_one  :closed_by, serializer: UserSerializer
    has_one  :processed_by, serializer: UserSerializer
    has_one  :cancelled_by, serializer: UserSerializer
    has_one  :process_completed_by, serializer: UserSerializer
    has_one  :dispatch_started_by, serializer: UserSerializer
    has_one  :submitted_by, serializer: UserSerializer

    def include_packages?
      @options[:include_packages]
    end

    def item_ids
    end

    def item_ids__sql
      'package_ids'
    end

    def local_order_id
      (object.detail_type == "LocalOrder" || object.detail_type == "StockitLocalOrder") ? object.detail_id : nil
    end

    def local_order_id__sql
      "case when (detail_type = 'LocalOrder' OR detail_type = 'StockitLocalOrder') then detail_id end"
    end

    def contact_id
      object.stockit_contact_id
    end

    def contact_id__sql
      "stockit_contact_id"
    end

    def gc_organisation_id
      object.organisation_id
    end

    def gc_organisation_id__sql
      "organisation_id"
    end

    def organisation_id
      object.stockit_organisation_id
    end

    def organisation_id__sql
    "stockit_organisation_id"
    end

    def activity
      object.stockit_activity.try(:name)
    end

    def activity__sql
      "(select a.name from stockit_activities a
        where a.id = orders.stockit_activity_id LIMIT 1)"
    end

    def country_name
      object.country.try(:name)
    end

    def country_name__sql
      "(select a.name_#{current_language} from countries a
        where a.id = orders.country_id LIMIT 1)"
    end

    def include_non_browse_details?
      !@options[:browse_order]
    end

    def include_cart_packages?
      !@options[:include_packages] && !@options[:include_order]
    end

    def include_orders_packages?
      !@options[:include_packages] && !@options[:include_order]
    end

    alias_method :include_stockit_contact?, :include_non_browse_details?
    alias_method :include_stockit_local_order?, :include_non_browse_details?
    alias_method :include_item_ids?, :include_packages?
  end
end
