class AddVanAllowedToCrossroadsTransport < ActiveRecord::Migration
  def change
    add_column :crossroads_transports, :is_van_allowed, :boolean, default: true
    CrossroadsTransport.find_by(name_en: "Disable").update_column(:is_van_allowed, false)
  end
end
