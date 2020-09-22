class AddPreferredContactNumberToOrganisationsUser < ActiveRecord::Migration[4.2]
  def change
    add_column :organisations_users, :preferred_contact_number, :string
  end
end
