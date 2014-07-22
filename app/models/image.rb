class Image < ActiveRecord::Base

  belongs_to :parent, polymorphic: true

  before_create :set_image_public_id

  private

  def set_image_public_id
    self.image = "v" + self.image
  end

end
