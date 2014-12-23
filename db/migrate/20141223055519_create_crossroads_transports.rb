class CreateCrossroadsTransports < ActiveRecord::Migration
  def change
    create_table :crossroads_transports do |t|
      t.string :name_en
      t.string :name_zh_tw

      t.timestamps
    end

    remove_column :offers, :crossroads_transport
    add_column    :offers, :crossroads_transport_id, :integer
  end
end
