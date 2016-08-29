class Image < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include CloudinaryHelper
  include Paranoid
  include PushUpdates

  has_one :user, inverse_of: :image
  has_many :packages, foreign_key: :favourite_image_id, inverse_of: :favourite_image, dependent: :nullify

  belongs_to :imageable, polymorphic: true

  before_destroy :delete_image_from_cloudinary,
    unless: "Rails.env.test? || has_multiple_items"
  after_update :clear_unused_transformed_images, unless: "Rails.env.test?"
  after_update :set_package_images, if: "favourite_changed? && imageable.is_a?(Item)"

  scope :donor_images, ->(donor_id) { joins(item: [:offer]).where(offers: {created_by_id: donor_id}) }

  def public_image_id
    cloudinary_id.split("/").last.split(".").first rescue nil
  end

  # required by PushUpdates and PaperTrail modules
  def offer
    imageable.try(:offer)
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

  def set_package_images
    item.packages.without_images.each do |package|
      package.update(favourite_image_id: id)
    end
  end

end
