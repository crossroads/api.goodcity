class CreateDeliveries < ActiveRecord::Migration
  def change
    create_table :deliveries do |t|
      t.integer  :offer_id
      t.integer  :contact_id
      t.integer  :schedule_id
      t.string   :delivery_type
      t.datetime :start
      t.datetime :finish

      t.timestamps
    end
  end
end
