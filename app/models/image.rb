class Image < ActiveRecord::Base

  belongs_to :parent, polymorphic: true
  before_destroy :delete_image_from_cloudinary

  scope :get_favourite, -> { where(favourite: true).first }

  def set_favourite
    update_column(:favourite, true)
  end

  def remove_favourite
    update_column(:favourite, false)
  end

  private

  def delete_image_from_cloudinary
    public_id = image.split('/').last.split('.').first rescue nil
    Cloudinary::Api.delete_resources([public_id]) if public_id
    true
  end
end
