class RemoveAuthorisedByIdFromOrder < ActiveRecord::Migration[4.2]
  def change
    remove_column :orders, :authorised_by_id
  end
end
