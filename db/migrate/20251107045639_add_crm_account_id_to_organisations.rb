class AddCrmAccountIdToOrganisations < ActiveRecord::Migration[6.1]
  def change
    add_column :organisations, :crm_account_id, :integer
  end
end
