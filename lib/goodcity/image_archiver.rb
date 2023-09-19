require 'azure/storage/blob'

module Goodcity

  # A class to handle archiving images from Cloudinary to Azure Storage to save space and bandwidth costs
  #   1. Decide with images to work on (generally related to packages dispatched a few years ago)
  #   2. Download images from Cloudinary
  #   3. Upload image to Azure Storage blob
  #   4. Update 'cloudinary_id' in Images table with Image::AZURE_IMAGE_PREFIX prefix to indicate it has moved.
  #      (Stock app will understand that the image needs to be fetched from Azure Storage rather than Cloudinary)
  #
  # WAYS TO USE:
  #   $ rake cloudinary:archive
  #   > Goodcity::ImageArchiver.new.process_images(package.images)
  #   > Goodcity::ImageArchiver.new.process_dispatched_packages
  #
  class ImageArchiver

    def initialize(options = {})
      # defaults
      @options = { min_age: 2.years.ago }.merge(options)
      # raise "Only run this in production or staging environments." unless %w(staging production).include?(Rails.env)
    end

    # An entry point for archiving images
    def process_images(images)
      [images].flatten.uniq.each do |image|
        move_to_azure_storage(image)
      end
    end

    # Criteria for archiving images on packages:
    #   - package is fully dispatched 
    #   - package has no available quantity
    #   - dispatched orders must have been sent prior to a 'min_age' threshold
    #   - package images are not already archived
    def process_dispatched_packages
      # TODO / WIP
      images = []

      images.find_each do |image|
        move_to_azure_storage(image)
      end
    end

    private

    #
    # The main algorithm
    # 1. Find the image on Cloudinary
    # 2. Download full size and one thumbnail
    # 3. Upload to Azure storage
    # 4. Prefix the database id with Image::AZURE_IMAGE_PREFIX to indicate that the image is archived
    def move_to_azure_storage(image)
      cloudinary_id = image.cloudinary_id # 1652280851/test/office_chair.jpg
      if cloudinary_id.starts_with?(Image::AZURE_IMAGE_PREFIX)
        log("Image has already been transferred to Azure Storage: #{cloudinary_id}")
        return
      end

      search = Cloudinary::Search
        .expression("version=#{image.cloudinary_id_version} AND public_id=#{image.cloudinary_id_public_id}")
        .max_results(1)
        .execute

      if (search["total_count"] == 0)
        log("Image not found on Cloudinary: #{cloudinary_id}")
        return
      end
      image_metadata = search['resources'].first
      if image_metadata['placeholder'].present?
        # Cloudinary replaces deleted images with a placeholder
        log("Image already deleted from Cloudinary: #{cloudinary_id}")
        return
      end

      # Generate mapping of image and thumbnail Cloudinary URLs to Azure Storage paths
      # E.g. { "http://res.cloudinary.com/ddoadcjjl/image/upload/v1652280851/test/office_chair.jpg" => "test/office_chair.jpg", 
      #        "http://res.cloudinary.com/ddoadcjjl/image/upload/a_0,c_fill,fl_progressive,w_300,h_300/v1652280851/test/office_chair.jpg" => "test/office_chair-300x300.jpg"}
      image_cloudinary_url = image_metadata["url"]
      image_mappings = { image_cloudinary_url => cloudinary_id }
      Image::AZURE_THUMBNAILS.each do |thumb|
        thumb_cloudinary_url = image_cloudinary_url.sub('upload', "upload/a_0,c_fill,fl_progressive,w_#{thumb[:width]},h_#{thumb[:height]}")
        thumb_blob_filename = cloudinary_id.sub(/\.([^\.]+)$/, "-#{thumb[:width]}x#{thumb[:height]}.\\1")
        image_mappings.merge!(thumb_cloudinary_url => thumb_blob_filename)
      end

      # Download image and thumbnails from Cloudinary and upload to Azure
      image_mappings.each do |cloudinary_url, blob_filename|
        content_type = nil
        image_content = nil
        ::URI.open(cloudinary_url, 'rb') do |file|
          content_type = file.content_type
          image_content = file.read
        end
        azure_client.create_block_blob(Image::AZURE_STORAGE_CONTAINER, blob_filename, image_content, { content_type: content_type })
      end

      # Update database and delete image on Cloudinary
      image.update_columns(cloudinary_id: "#{Image::AZURE_IMAGE_PREFIX}#{cloudinary_id}")
      if (Image.where(cloudinary_id: cloudinary_id).size == 0)
        public_id = image.cloudinary_id_public_id
        response = Cloudinary::Api.delete_resources(public_id)
        result = response["deleted"][public_id]]
        if (result == "deleted")
          log("Image successfully deleted from Cloudinary: #{public_id}")
        else
          log("Error '#{result}' when deleting image from Cloudinary: #{public_id}")
        end
      end
    end

    def log(msg)
      puts msg
    end

    # Uses ENV vars: AZURE_STORAGE_ACCOUNT, AZURE_STORAGE_ACCESS_KEY
    def azure_client
      @azure_client ||= Azure::Storage::Blob::BlobService.create
    end

  end
end
