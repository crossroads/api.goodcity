class Image < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include CloudinaryHelper
  include Paranoid
  include PushUpdates

  has_one :user, inverse_of: :image
  belongs_to :item, inverse_of: :images
  before_destroy :delete_image_from_cloudinary,
    unless: "Rails.env.test? || has_multiple_items"

  def public_image_id
    cloudinary_id.split("/").last.split(".").first rescue nil
  end

  # required by PushUpdates and PaperTrail modules
  def offer
    item.try(:offer)
  end

  private

  def delete_image_from_cloudinary
    image_id = public_image_id
    CloudinaryImageCleanupJob.perform_later(image_id) if image_id
    true
  end

  def has_multiple_items
    Image.where(cloudinary_id: cloudinary_id).count > 1
  end

end
