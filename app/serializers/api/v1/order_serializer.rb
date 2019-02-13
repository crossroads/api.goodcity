module Api::V1
  class OrderSerializer < OrderShallowSerializer
    attributes :item_ids, :cancellation_reason, :unread_messages_count
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
    has_many :goodcity_requests, serializer: GoodcityRequestSerializer
    has_many :messages, serializer: MessageSerializer
    has_one  :closed_by, serializer: UserSerializer
    has_one  :processed_by, serializer: UserSerializer
    has_one  :cancelled_by, serializer: UserSerializer
    has_one  :booking_type, serializer: BookingTypeSerializer
    has_one  :process_completed_by, serializer: UserSerializer
    has_one  :dispatch_started_by, serializer: UserSerializer
    has_one  :submitted_by, serializer: UserSerializer
    has_one  :beneficiary, serializer: BeneficiarySerializer
    has_one  :address, serializer: AddressSerializer
    has_one  :district, serializer: DistrictSerializer

    def unread_messages_count
      object.subscriptions.where(state: 'unread', user_id: object.created_by_id).count
    end

    def unread_messages_count__sql
      "(select count(*) from subscriptions s where s.order_id = orders.id and s.state = 'unread' and s.user_id = orders.created_by_id)"
    end


    def item_ids
    end

    def item_ids__sql
      'package_ids'
    end

    def include_packages?
      @options[:include_packages]
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
