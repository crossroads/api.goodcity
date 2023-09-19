class ImageCleanupJob < ActiveJob::Base
  queue_as :low

  # cloudinary_id: 1652280851/test/red_chair.jpg
  def perform(cloudinary_id)
    return if cloudinary_id.blank?
    if (ENV['PREVENT_CLOUDINARY_IMAGE_DELETION'] == 'true') or %w(development test).include?(Rails.env)
      Rails.logger.info(class: self.class.name, msg: "Prevented from deleting image", cloudinary_id: cloudinary_id)
    else
      if cloudinary_id.starts_with?(Image::AZURE_IMAGE_PREFIX)
        # Image is stored in Azure
        azure_client = Azure::Storage::Blob::BlobService.create
        blob_path = cloudinary_id.gsub(Image::AZURE_IMAGE_PREFIX, '')
        azure_client.delete_blob(Image::AZURE_STORAGE_CONTAINER, blob_path)
        Image::AZURE_THUMBNAILS.each do |thumb|
          thumb_blob_path = blob_path.sub(/\.([^\.]+)$/, "-#{thumb[:width]}x#{thumb[:height]}.\\1")
          azure_client.delete_blob(Image::AZURE_STORAGE_CONTAINER, thumb_blob_path)
        end
        Rails.logger.info(class: self.class.name, msg: "Deleted image and thumbnails from Azure Storage", cloudinary_id: cloudinary_id)
      else
        # "1652280851/test/red_chair.jpg" -> "test/red_chair"
        public_id = Image.new(cloudinary_id: cloudinary_id).cloudinary_id_public_id
        Cloudinary::Api.delete_resources([public_id])
        Rails.logger.info(class: self.class.name, msg: "Deleted image from Cloudinary", cloudinary_id: public_id)
      end
    end
  end
end
