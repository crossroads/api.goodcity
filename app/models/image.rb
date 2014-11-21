class Image < ActiveRecord::Base

  include CloudinaryHelper
  include Paranoid

  belongs_to :item, inverse_of: :images
  before_destroy :delete_image_from_cloudinary, unless: "Rails.env.test?"

  private

  def delete_image_from_cloudinary
    public_id = cloudinary_id.split('/').last.split('.').first rescue nil
    Cloudinary::Api.delete_resources([public_id]) if public_id
    true
  end
end
