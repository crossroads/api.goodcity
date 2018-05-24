class Box < ActiveRecord::Base
  has_many :packages
  belongs_to :pallet

  after_destroy :remove_box_id_from_packages

  private

  def remove_box_id_from_packages
    packages.update_all(box_id: nil)
  end
end
