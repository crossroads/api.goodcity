class AddTransportDetailsColumnsToOffers < ActiveRecord::Migration[4.2]
  def change
    add_column :offers, :gogovan_transport, :string
    add_column :offers, :crossroads_transport, :string
  end
end
