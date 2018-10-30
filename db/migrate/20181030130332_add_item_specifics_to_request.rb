class AddItemSpecificsToRequest < ActiveRecord::Migration
  def change
  	add_column :goodcity_requests, :item_specifics, :text
  end
end
