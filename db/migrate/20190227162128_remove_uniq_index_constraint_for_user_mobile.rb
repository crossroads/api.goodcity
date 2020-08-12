class RemoveUniqIndexConstraintForUserMobile < ActiveRecord::Migration[4.2]
  def change
    remove_index :users, :mobile
    add_index :users, :mobile
  end
end
