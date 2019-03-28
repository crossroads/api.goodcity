class AddPreferredContactNumberToOrganisationsUser < ActiveRecord::Migration
  def change
    add_column :organisations_users, :preferred_contact_number, :string
  end
end
