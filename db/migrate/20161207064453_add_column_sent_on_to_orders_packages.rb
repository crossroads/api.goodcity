class AddColumnSentOnToOrdersPackages < ActiveRecord::Migration
  def change
    add_column :orders_packages, :sent_on, :datetime
  end
end
