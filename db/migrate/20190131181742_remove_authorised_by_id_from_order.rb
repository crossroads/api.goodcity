class RemoveAuthorisedByIdFromOrder < ActiveRecord::Migration
  def change
  	remove_column :orders, :authorised_by_id
  end
end
