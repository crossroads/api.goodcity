class AddDetailToPackages < ActiveRecord::Migration
  def change
    add_reference :packages, :detail, polymorphic: true, index: true
  end
end
