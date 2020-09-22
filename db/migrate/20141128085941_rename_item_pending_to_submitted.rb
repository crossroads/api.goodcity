class RenameItemPendingToSubmitted < ActiveRecord::Migration[4.2]
  def change
    Item.where(state: "pending").update_all(state: "submitted")
  end
end
