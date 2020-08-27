class AddStatusToOrganisationsUsers < ActiveRecord::Migration
  def change
    add_column :organisations_users, :status, :string, index: true, default: 'pending'
  end
end
