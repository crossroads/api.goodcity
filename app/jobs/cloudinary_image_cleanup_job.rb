class CloudinaryImageCleanupJob < ActiveJob::Base
  queue_as :low

  def perform(cloudinary_image_id)
    unless %w(development test).include?(Rails.env)
      Cloudinary::Api.delete_resources([cloudinary_image_id])
    end
  end
end
