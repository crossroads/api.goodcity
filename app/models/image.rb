class Image < ActiveRecord::Base

  belongs_to :parent, polymorphic: true

  scope :get_favourite, -> { where(favourite: true).first }

  def set_favourite
    update_column(:favourite, true)
  end

  def remove_favourite
    update_column(:favourite, false)
  end

end
