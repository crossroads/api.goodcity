class AddDisaledToGogovanTransports < ActiveRecord::Migration[4.2]
  def change
    add_column :gogovan_transports, :disabled, :boolean, default: false

    ActiveRecord::Base.connection.execute("update gogovan_transports set disabled = true where name_en = 'Disable'")
  end
end
