require 'goodcity/image_archiver'

# ImageArchiveJob.perform_later(image_ids)
class ImageArchiveJob < ActiveJob::Base
  queue_as :low

  def perform(image_ids)
    image_ids = [image_ids].flatten.uniq.compact
    return if image_ids.empty?

    images = Image.where(id: image_ids).to_a
    Goodcity::ImageArchiver.new.process_images(images)

  end
end
