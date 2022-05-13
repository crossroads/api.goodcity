class AddDistrictToOffers < ActiveRecord::Migration[6.1]
  def change
    add_reference :offers, :district, index: true
  end
end
