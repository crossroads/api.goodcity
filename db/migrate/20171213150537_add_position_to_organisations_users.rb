class AddPositionToOrganisationsUsers < ActiveRecord::Migration
  def change
    add_column :organisations_users, :position, :string
  end
end
