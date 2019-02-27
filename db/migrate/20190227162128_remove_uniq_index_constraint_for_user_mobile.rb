class RemoveUniqIndexConstraintForUserMobile < ActiveRecord::Migration
  def change
    remove_index :users, :mobile
    add_index :users, :mobile
  end
end
