module Api::V1
  class OrderSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :status, :created_at, :code, :detail_type, :id, :detail_id,
      :contact_id, :local_order_id, :organisation_id, :description, :activity,
      :country_name, :state, :purpose_description

    has_one :stockit_contact, serializer: StockitContactSerializer, root: :contact
    has_one :stockit_organisation, serializer: StockitOrganisationSerializer, root: :organisation
    has_one :stockit_local_order, serializer: StockitLocalOrderSerializer, root: :local_order
    has_many :packages, serializer: StockitItemSerializer, root: :items
    has_many :cart_packages, serializer: BrowsePackageSerializer, root: :packages
    has_many :orders_packages, serializer: OrdersPackageSerializer

    def include_packages?
      @options[:include_order]
    end

    def local_order_id
      object.detail_type == "LocalOrder" ? object.detail_id : nil
    end

    def local_order_id__sql
      "case when detail_type = 'LocalOrder' then detail_id end"
    end

    def contact_id
      object.stockit_contact_id
    end

    def contact_id__sql
      "stockit_contact_id"
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
  end
end
