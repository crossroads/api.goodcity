class AddDistrictAssociationToUser < ActiveRecord::Migration
  def change
    add_reference :users, :district, index: true
  end
end
