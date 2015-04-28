class Image < ActiveRecord::Base
  has_paper_trail
  include CloudinaryHelper
  include Paranoid
  include PushUpdates

  has_one :user, inverse_of: :image
  belongs_to :item, inverse_of: :images
  before_destroy :delete_image_from_cloudinary, unless: "Rails.env.test?"

  def public_image_id
    cloudinary_id.split("/").last.split(".").first rescue nil
  end

  private

  def delete_image_from_cloudinary
    image_id = public_image_id
    CloudinaryImageCleanupJob.perform_later(image_id) if image_id
    true
  end

  # required by PushUpdates module
  def offer
    item.offer unless item.nil?
  end
end
