module Api::V1
  class OrderShallowSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :status, :created_at, :code, :detail_type, :id, :detail_id,
      :contact_id, :local_order_id, :organisation_id, :description, :activity,
      :country_name, :state, :purpose_description, :created_by_id, :cancellation_reason,
      :gc_organisation_id, :processed_at, :processed_by_id, :cancelled_at, :cancelled_by_id,
      :process_completed_at, :process_completed_by_id, :closed_at, :closed_by_id, :dispatch_started_at,
      :dispatch_started_by_id, :submitted_at, :submitted_by_id, :people_helped, :beneficiary_id,
      :address_id, :district_id, :booking_type_id, :unread_messages_count

    def unread_messages_count
      object.subscriptions.where(state: 'unread').count
    end

    def unread_messages_count__sql
      "(select count(*) from subscriptions s where s.order_id = orders.id and s.state = 'unread')"
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
  end
end

