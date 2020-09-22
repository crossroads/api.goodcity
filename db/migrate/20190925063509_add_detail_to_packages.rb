class AddDetailToPackages < ActiveRecord::Migration[4.2]
  def change
    add_reference :packages, :detail, polymorphic: true, index: true
  end
end
