class AddGih3IdToOrganisation < ActiveRecord::Migration[4.2]
  def change
    add_column :organisations, :gih3_id, :integer
  end
end
