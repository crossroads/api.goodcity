class ConvertTimestampWithoutTzToTimestampWithTz < ActiveRecord::Migration
  def up

    model_names = ['address', 'auth_token', 'beneficiary', 'booking_type', 'box',
    'braintree_transaction', 'cancellation_reason', 'contact', 'country',
    'crossroads_transport', 'delivery', 'district', 'donor_condition', 'gogovan_order',
    'gogovan_transport', 'goodcity_request', 'holiday', 'identity_type', 'image',
    'inventory_number', 'item', 'location', 'message', 'offer', 'order', 'orders_package',
    'orders_purpose', 'order_transport', 'organisation', 'organisations_user',
    'organisation_type', 'package_categories_package_type', 'package_category',
    'package', 'packages_location', 'package_type', 'pallet', 'permission', 'purpose',
    'rejection_reason', 'role_permission', 'role', 'schedule', 'stockit_activity',
    'stockit_contact', 'stockit_local_order', 'stockit_organisation', 'subpackage_type',
    'subscription', 'territory', 'timeslot', 'user', 'user_role', 'version'].freeze

    model_names.each do |model_name|
      model = model_name.camelize.constantize
      model.columns.each do |column|
        if column.sql_type == "timestamp without time zone"
          change_column(model.table_name, column.name, 'timestamp with time zone')
        end
      end
    end

  end

  def down

    model_names = ['address', 'auth_token', 'beneficiary', 'booking_type', 'box',
    'braintree_transaction', 'cancellation_reason', 'contact', 'country',
    'crossroads_transport', 'delivery', 'district', 'donor_condition', 'gogovan_order',
    'gogovan_transport', 'goodcity_request', 'holiday', 'identity_type', 'image',
    'inventory_number', 'item', 'location', 'message', 'offer', 'order', 'orders_package',
    'orders_purpose', 'order_transport', 'organisation', 'organisations_user',
    'organisation_type', 'package_categories_package_type', 'package_category',
    'package', 'packages_location', 'package_type', 'pallet', 'permission', 'purpose',
    'rejection_reason', 'role_permission', 'role', 'schedule', 'stockit_activity',
    'stockit_contact', 'stockit_local_order', 'stockit_organisation', 'subpackage_type',
    'subscription', 'territory', 'timeslot', 'user', 'user_role', 'version'].freeze

    model_names.each do |model_name|
      model = model_name.camelize.constantize
      model_name.camelize.constantize.columns.each do |column|
        if column.sql_type == "timestamp with time zone"
          change_column(model.table_name, column.name, 'timestamp without time zone')
        end
      end
    end

  end
end
