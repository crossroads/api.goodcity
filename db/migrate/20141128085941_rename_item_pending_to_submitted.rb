class RenameItemPendingToSubmitted < ActiveRecord::Migration
  def change
    Item.where(state: "pending").update_all(state: "submitted")
  end
end
