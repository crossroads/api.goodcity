module Api::V1
  class OrderShallowSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :created_at, :code, :detail_type, :id, :detail_id,
               :contact_id, :local_order_id, :organisation_id,
               :description, :country_name, :country_id, :state,
               :purpose_description, :created_by_id, :cancel_reason,
               :processed_at, :processed_by_id,
               :cancelled_at, :cancelled_by_id,
               :process_completed_at, :process_completed_by_id, :closed_at,
               :closed_by_id, :dispatch_started_at,
               :dispatch_started_by_id, :submitted_at, :submitted_by_id,
               :people_helped, :beneficiary_id, :address_id, :district_id,
               :booking_type_id, :staff_note, :cancellation_reason_id,
               :shipment_date

    has_many :messages, serializer: MessageSerializer

    def include_messages?
      @options[:include_messages]
    end

    def local_order_id
      (object.detail_type == "LocalOrder" || object.detail_type == "StockitLocalOrder") ? object.detail_id : nil
    end

    def contact_id
      object.stockit_contact_id
    end

    def organisation_id
      object.organisation_id
    end

    def activity
      object.stockit_activity.try(:name)
    end

    def country_name
      object.country.try(:name)
    end
  end
end
