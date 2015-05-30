class AddVanAllowedToCrossroadsTransport < ActiveRecord::Migration
  def change
    add_column :crossroads_transports, :is_van_allowed, :boolean, default: true
    transport = CrossroadsTransport.find_by(name_en: "Disable")
    transport.update_column(:is_van_allowed, false) unless transport.nil?
  end
end
