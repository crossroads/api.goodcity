class AddTitleZhTwToUsers < ActiveRecord::Migration
  def change
    add_column :users, :title_zh_tw, :string
  end
end
