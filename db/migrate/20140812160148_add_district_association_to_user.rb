class AddDistrictAssociationToUser < ActiveRecord::Migration[4.2]
  def change
    add_reference :users, :district, index: true
  end
end
