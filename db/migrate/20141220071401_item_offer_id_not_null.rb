class ItemOfferIdNotNull < ActiveRecord::Migration[4.2]
  def change
    Item.where(offer_id: nil).delete_all
    change_column :items, :offer_id, :integer, null: false
  end
end
