#
# Images are uploaded directly to Cloudinary
# Once a package is fully dispatched (nothing left in stock), and some time has passed,
#   we will move the image and some thumbnails from Cloudinary to Azure Storage
# This saves space and money.
class Image < ApplicationRecord
  has_paper_trail versions: { class_name: 'Version' }, meta: { related: :offer }
  include CloudinaryHelper
  include Paranoid
  include PushUpdatesMinimal
  include ShareSupport

  AZURE_THUMBNAILS = [ {width: 300, height: 300} ] # What thumbnail sizes to store on Azure
  AZURE_STORAGE_CONTAINER = 'images' # name of the blob container in Azure Storage
  AZURE_IMAGE_PREFIX = 'azure-' # prefix used in 'cloudinary_id' field to distinguish Azure from Cloudinary

  has_one :user, inverse_of: :image
  belongs_to :item
  belongs_to :offer

  belongs_to :imageable, polymorphic: true

  before_save :handle_heic_image
  before_destroy :delete_image_from_storage, unless: :has_multiple_items
  after_update :clear_unused_transformed_images

  after_update :reset_favourite, if: :saved_change_to_favourite?

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

  # "1652280851/test/office_chair.jpg" returns "1652280851"
  def cloudinary_id_version
    cloudinary_id.split('/')[0]
  end

  # "1652280851/test/office_chair.jpg" returns "test/office_chair"
  def cloudinary_id_public_id
    cloudinary_id.split('/').drop(1).join('/').sub(/\.[^\.]+$/, '')
  end

  # required by PushUpdates and PaperTrail modules
  def offer
    imageable.try(:offer)
  end

  def reset_favourite
    favourite && imageable &&
    imageable.images.where.not(id: id).each{ |img| img.update(favourite: false) }
  end

  private

  def clear_unused_transformed_images
    CloudinaryCleanTransformedImagesJob.perform_later(id)
    true
  end

  def delete_image_from_storage
    ImageCleanupJob.perform_later(cloudinary_id)
    true
  end

  def has_multiple_items
    Image.where(cloudinary_id: cloudinary_id).count > 1
  end

  def handle_heic_image
    self.cloudinary_id = self.cloudinary_id.gsub(/heic/i, "jpg")
  end
end
