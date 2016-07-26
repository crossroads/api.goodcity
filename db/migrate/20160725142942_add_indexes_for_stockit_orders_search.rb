class AddIndexesForStockitOrdersSearch < ActiveRecord::Migration

  def up
    unless index_exists?(:stockit_designations, :code, name: "st_designations_code_idx")
      execute "CREATE INDEX st_designations_code_idx ON stockit_designations USING gin (code gin_trgm_ops);"
    end

    unless index_exists?(:stockit_organisations, :name, name: "st_organisations_name_idx")
      execute "CREATE INDEX st_organisations_name_idx ON stockit_organisations USING gin (name gin_trgm_ops);"
    end

    unless index_exists?(:stockit_local_orders, :client_name, name: "st_local_orders_client_name_idx")
      execute "CREATE INDEX st_local_orders_client_name_idx ON stockit_local_orders USING gin (client_name gin_trgm_ops);"
    end

    unless index_exists?(:stockit_contacts, :first_name, name: "st_contacts_first_name_idx")
      execute "CREATE INDEX st_contacts_first_name_idx ON stockit_contacts USING gin (first_name gin_trgm_ops);"
    end

    unless index_exists?(:stockit_contacts, :last_name, name: "st_contacts_last_name_idx")
      execute "CREATE INDEX st_contacts_last_name_idx ON stockit_contacts USING gin (last_name gin_trgm_ops);"
    end

    unless index_exists?(:stockit_contacts, :mobile_phone_number, name: "st_contacts_mobile_phone_number_idx")
      execute "CREATE INDEX st_contacts_mobile_phone_number_idx ON stockit_contacts USING gin (mobile_phone_number gin_trgm_ops);"
    end

    unless index_exists?(:stockit_contacts, :phone_number, name: "st_contacts_phone_number_idx")
      execute "CREATE INDEX st_contacts_phone_number_idx ON stockit_contacts USING gin (phone_number gin_trgm_ops);"
    end
  end

  def down
    execute "DROP INDEX st_designations_code_idx;"
    execute "DROP INDEX st_organisations_name_idx;"
    execute "DROP INDEX st_local_orders_client_name_idx;"
    execute "DROP INDEX st_contacts_first_name_idx;"
    execute "DROP INDEX st_contacts_last_name_idx;"
    execute "DROP INDEX st_contacts_mobile_phone_number_idx;"
    execute "DROP INDEX st_contacts_phone_number_idx;"
  end

end
