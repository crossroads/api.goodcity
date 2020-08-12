class UpdatePreviousItemsToSubmitted < ActiveRecord::Migration[4.2]
  def change
    Item.where("created_at < '2014/12/2'").update_all(state: 'submitted')
  end
end
