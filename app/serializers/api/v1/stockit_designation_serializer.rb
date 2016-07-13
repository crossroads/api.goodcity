module Api::V1
  class StockitDesignationSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :status, :code, :detail_type, :id, :detail_id, :contact_id, :local_order_id, :organisation_id, 
      :description, :activity

    has_one :stockit_contact, serializer: StockitContactSerializer, root: :contact
    has_one :stockit_organisation, serializer: StockitOrganisationSerializer, root: :organisation
    has_one :stockit_local_order, serializer: StockitLocalOrderSerializer, root: :local_order
    has_many :packages, serializer: StockitItemSerializer, root: :items

    def include_packages?
      !@options[:include_stockit_designation]
    end

    def local_order_id
      object.detail_type == "StockitLocalOrder" ? object.detail_id : nil
    end

    def local_order_id__sql
      "case when detail_type = 'StockitLocalOrder' then detail_id end"
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
        where a.id = stockit_designations.stockit_activity_id LIMIT 1)"
    end
  end
end
