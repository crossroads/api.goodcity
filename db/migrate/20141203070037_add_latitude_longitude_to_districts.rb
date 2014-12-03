class AddLatitudeLongitudeToDistricts < ActiveRecord::Migration
  def change
    add_column :districts, :latitude, :float
    add_column :districts, :longitude, :float
  end
end
