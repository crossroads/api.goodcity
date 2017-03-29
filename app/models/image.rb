class Image < ApplicationRecord
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include CloudinaryHelper
  include Paranoid
  include PushUpdates

  has_one :user, inverse_of: :image
  belongs_to :imageable, polymorphic: true, touch: true

  before_destroy :delete_image_from_cloudinary, unless: "has_multiple_items"
  after_update :clear_unused_transformed_images

  after_update :reset_favourite,  if: :favourite_changed?

  scope :donor_images, ->(donor_id) { joins(item: [:offer]).where(offers: {created_by_id: donor_id}) }

  def public_image_id
    cloudinary_id.split("/").last.split(".").first rescue nil
  end

  # required by PushUpdates and PaperTrail modules
  def offer
    imageable.try(:offer)
  end

  def reset_favourite
    favourite and imageable.images.where.not(id: id).update_all(favourite: false)
  end

  private

  def clear_unused_transformed_images
    image_id = public_image_id
    CloudinaryCleanTransformedImagesJob.perform_later(image_id, self.id) if image_id
    true
  end

  def delete_image_from_cloudinary
    image_id = public_image_id
    CloudinaryImageCleanupJob.perform_later(image_id) if image_id
    true
  end

  def has_multiple_items
    Image.where(cloudinary_id: cloudinary_id).count > 1
  end

end
