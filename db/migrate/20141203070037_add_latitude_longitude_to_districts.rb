class AddLatitudeLongitudeToDistricts < ActiveRecord::Migration[4.2]
  def change
    add_column :districts, :latitude, :float
    add_column :districts, :longitude, :float
  end
end
