class CloudinaryImageCleanupJob < ActiveJob::Base
  queue_as :low

  def perform(cloudinary_image_id)
    return if %w(development test).include?(Rails.env)
    if (ENV['PREVENT_CLOUDINARY_IMAGE_DELETION'] == 'true')
      Rails.logger.info("CloudinaryImageCleanupJob: prevented from deleting image '#{cloudinary_image_id}'")
    else
      Rails.logger.info("CloudinaryImageCleanupJob: deleting image '#{cloudinary_image_id}'")
      Cloudinary::Api.delete_resources([cloudinary_image_id])
    end
  end
end
