class Image < ApplicationRecord
  has_paper_trail versions: { class_name: 'Version' }, meta: { related: :offer }
  include CloudinaryHelper
  include Paranoid
  include PushUpdatesMinimal

  has_one :user, inverse_of: :image
  belongs_to :imageable, polymorphic: true, touch: true

  before_save :handle_heic_image
  before_destroy :delete_image_from_cloudinary, unless: :has_multiple_items
  after_update :clear_unused_transformed_images

  after_update :reset_favourite, if: :favourite_changed?

  scope :donor_images, ->(donor_id) { joins(item: [:offer]).where(offers: { created_by_id: donor_id }) }

  # Live update rules
  after_save :push_changes
  after_destroy :push_changes
  push_targets do |record|
    package = record.imageable if record.imageable_type == "Package"
    channels = []
    if record.offer
      channels << Channel.private_channels_for(record.offer.created_by_id, DONOR_APP)
      channels << Channel::STAFF_CHANNEL
    end
    if package
      channels << Channel::STOCK_CHANNEL if package.inventory_number.present?
      channels << Channel::BROWSE_CHANNEL if (package.allow_web_publish || package.allow_web_publish_was)
    end
    channels
  end

  def public_image_id
    cloudinary_id.split("/").last.split(".").first rescue nil
  end

  # required by PushUpdates and PaperTrail modules
  def offer
    imageable.try(:offer)
  end

  def reset_favourite
    favourite && imageable &&
    imageable.images.where.not(id: id).each{ |img| img.update_attributes(favourite: false) }
  end

  private

  def clear_unused_transformed_images
    image_id = public_image_id
    CloudinaryCleanTransformedImagesJob.perform_later(image_id, id) if image_id
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

  def handle_heic_image
    self.cloudinary_id = self.cloudinary_id.gsub(/heic/i, "jpg")
  end
end
