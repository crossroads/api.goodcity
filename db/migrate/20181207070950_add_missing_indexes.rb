class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :orders_packages, [:order_id, :package_id]
    add_index :orders_packages, :order_id
    add_index :orders_packages, :package_id

    add_index :items, :offer_id
    add_index :packages, :order_id
    add_index :packages, :item_id
    add_index :packages, :offer_id
    add_index :packages, :package_type_id
    add_index :packages, :location_id

    add_index :offers, :created_by_id
    add_index :messages, :offer_id
    add_index :messages, :item_id
    add_index :messages, :sender_id

    add_index :addresses, :district_id
    add_index :addresses, [:addressable_id, :addressable_type]
    add_index :auth_tokens, :user_id
    add_index :beneficiaries, :created_by_id
    add_index :boxes, :pallet_id
    add_index :deliveries, :contact_id
    add_index :deliveries, :gogovan_order_id
    add_index :deliveries, :offer_id
    add_index :deliveries, :schedule_id
    add_index :districts, :territory_id
    add_index :goodcity_requests, :created_by_id
    add_index :images, [:imageable_id, :imageable_type]
    add_index :items, :donor_condition_id
    add_index :items, :package_type_id
    add_index :items, :rejection_reason_id
    add_index :offers, :cancellation_reason_id
    add_index :offers, :closed_by_id
    add_index :offers, :crossroads_transport_id
    add_index :offers, :gogovan_transport_id
    add_index :offers, :received_by_id
    add_index :offers, :reviewed_by_id
    add_index :order_transports, :booking_type_id
    add_index :order_transports, :contact_id
    add_index :order_transports, :gogovan_order_id
    add_index :order_transports, :gogovan_transport_id
    add_index :order_transports, :order_id
    add_index :orders, :address_id
    add_index :orders, :beneficiary_id
    add_index :orders, :cancelled_by_id
    add_index :orders, :closed_by_id
    add_index :orders, :country_id
    add_index :orders, :created_by_id
    add_index :orders, :detail_id
    add_index :orders, :dispatch_started_by_id
    add_index :orders, :organisation_id
    add_index :orders, :process_completed_by_id
    add_index :orders, :processed_by_id
    add_index :orders, :stockit_activity_id
    add_index :orders, :stockit_contact_id
    add_index :orders, :stockit_organisation_id
    add_index :orders, :submitted_by_id
    add_index :orders, [:detail_id, :detail_type]
    add_index :orders_packages, :updated_by_id
    add_index :orders_purposes, :order_id
    add_index :orders_purposes, :purpose_id
    add_index :package_types, :location_id
    add_index :packages, :box_id
    add_index :packages, :donor_condition_id
    add_index :packages, :pallet_id
    add_index :packages, :set_item_id
    add_index :packages, :stockit_designated_by_id
    add_index :packages, :stockit_moved_by_id
    add_index :packages, :stockit_sent_by_id

    add_index :role_permissions, :permission_id
    add_index :role_permissions, :role_id
    add_index :subpackage_types, :package_type_id
    add_index :subpackage_types, :subpackage_type_id
    add_index :subpackage_types, [:package_type_id, :package_type_id]
    add_index :user_roles, :role_id
    add_index :user_roles, :user_id
    add_index :users, :image_id

  end
end
