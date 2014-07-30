class Image < ActiveRecord::Base

  belongs_to :parent, polymorphic: true

  def self.get_favourite
    where(favourite: true).first
  end

  def set_favourite
    update_column(:favourite, true)
  end

  def remove_favourite
    update_column(:favourite, false)
  end

end
