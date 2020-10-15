class AddOfferIdItemIdToMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :messages, :offer_id, :integer
    add_column :messages, :item_id, :integer
    add_column :messages, :state, :string
    rename_column :messages, :private, :is_private
  end
end
