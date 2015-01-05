class CloudinaryImageCleanupJob < ActiveJob::Base
  queue_as :cloudinary

  def perform(image)
    public_id = image.public_image_id
    Cloudinary::Api.delete_resources([public_id]) if public_id
  end
end
