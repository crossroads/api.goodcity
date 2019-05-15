class CloudinaryImageCleanupJob < ActiveJob::Base
  queue_as :low

  def perform(cloudinary_image_id)
    return if %w(development test).include?(Rails.env)
    return if (ENV['PREVENT_CLOUDINARY_IMAGE_DELETION'] == 'true')
    Cloudinary::Api.delete_resources([cloudinary_image_id])
  end
end
