class AddGih3IdToOrganisation < ActiveRecord::Migration
  def change
    add_column :organisations, :gih3_id, :integer
  end
end
