class CloudinaryCleanTransformedImagesJob < ActiveJob::Base
  queue_as :low

  def perform(cloudinary_image_id, image_id)

    begin
      response = Cloudinary::Api.resource(cloudinary_image_id)
    rescue Cloudinary::Api::NotFound
      # don't proceed
      Rails.logger.info("Cloudinary image #{cloudinary_image_id} not found")
      return
    end
    
    derived_ids = []
    image = Image.find_by(id: image_id)

    if image
      response["derived"].each do |k|
        name = k["transformation"]
        if name.include?("a_") && name.exclude?("a_#{image.angle}")
          derived_ids << k["id"]
        end
      end

      Cloudinary::Api.delete_derived_resources(derived_ids) unless derived_ids.blank?
    end
  end
end


