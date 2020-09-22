class AddColumnSentOnToOrdersPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :orders_packages, :sent_on, :datetime
  end
end
