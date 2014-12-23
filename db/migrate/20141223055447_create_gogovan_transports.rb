class CreateGogovanTransports < ActiveRecord::Migration
  def change
    create_table :gogovan_transports do |t|
      t.string :name_en
      t.string :name_zh_tw

      t.timestamps
    end

    remove_column :offers, :gogovan_transport
    add_column    :offers, :gogovan_transport_id, :integer
  end
end
