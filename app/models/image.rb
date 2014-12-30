class Image < ActiveRecord::Base

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

  #required by PusherUpdates module
  def donor_user_id
    item.offer.created_by_id
  end
end
