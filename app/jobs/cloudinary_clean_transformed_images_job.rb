class CloudinaryCleanTransformedImagesJob < ActiveJob::Base
  queue_as :low

  def perform(image_id)
    image = Image.find_by(id: image_id)
    if image
      public_id = image.cloudinary_id_public_id
      begin
        response = Cloudinary::Api.resource(public_id)
      rescue Cloudinary::BaseApi::NotFound
        Rails.logger.info(class: self.class.name, msg: "Image not found", public_id: public_id)
        return
      end

      derived_ids = []
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


