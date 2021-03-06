module Api::V1
  class OrderSerializer < OrderShallowSerializer
    attributes :item_ids, :cancellation_reason_id, :cancel_reason, :shipment_date
    has_one :created_by, serializer: UserProfileSerializer, root: :user
    has_one :stockit_contact, serializer: StockitContactSerializer
    has_one :stockit_organisation, serializer: StockitOrganisationSerializer, root: :organisation
    has_one :stockit_local_order, serializer: StockitLocalOrderSerializer, root: :local_order
    has_one :order_transport, serializer: OrderTransportSerializer
    has_one :organisation, serializer: OrganisationSerializer
    has_many :packages, serializer: StockitItemSerializer, root: :items
    has_many :orders_packages, serializer: OrdersPackageSerializer
    has_many :orders_purposes, serializer: OrdersPurposeSerializer
    has_many :goodcity_requests, serializer: GoodcityRequestSerializer
    has_many :orders_process_checklists, serializer: OrderProcessChecklistSerializer
    has_many :messages, serializer: MessageSerializer, polymorphic: true
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
    has_one  :cancellation_reason, serializer: CancellationReasonSerializer

    def item_ids
      object.packages.pluck(:id)
    end

    def include_packages?
      @options[:include_packages]
    end

    def include_non_browse_details?
      !@options[:browse_order]
    end

    def include_orders_packages?
      @options[:include_orders_packages] || (
        !@options[:include_packages] && !@options[:include_order]
      )
    end

    def include_messages?
      @options[:include_messages]
    end

    alias include_stockit_contact? include_non_browse_details?
    alias include_stockit_local_order? include_non_browse_details?
    alias include_item_ids? include_packages?
  end
end
