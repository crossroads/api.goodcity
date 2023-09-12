require 'azure/storage/blob'

module Goodcity

  # A class to handle archiving images from Cloudinary to Azure Storage to save space and bandwidth costs
  #   1. Decide with images to work on (generally related to packages dispatched a few years ago)
  #   2. Download images from Cloudinary
  #   3. Upload image to Azure Storage blob
  #   4. Update 'cloudinary_id' in Images table with 'azure-' prefix to indicate it has moved.
  #      (Stock app will understand that the image needs to be fetched from Azure Storage rather than Cloudinary)
  #
  # WAYS TO USE:
  #   $ rake cloudinary:archive
  #   > Goodcity::ImageArchiver.new.process!
  #   > Goodcity::ImageArchiver.new.move_to_azure_storage(image)
  #
  class ImageArchiver

    def initialize(options = {})
      # defaults
      @options = { min_age: 2.years.ago }.merge(options)
      # raise "Only run this in production env." unless Rails.env.production?
    end

    def process!
      images = Image
        .where("created_at < ?", @options[:min_age].to_s(:db))
        .where.not("cloudinary_id LIKE 'azure-%'")
        .order('created_at asc')

      images.find_each do |image|
        move_to_azure_storage(image)
      end
    end

    def move_to_azure_storage(image)
      cloudinary_id = image.cloudinary_id # 1652280851/test/office_chair.jpg
      if cloudinary_id.starts_with?('azure-')
        log("Image has already been transferred to Azure Storage: #{cloudinary_id}")
        return
      end
      params = parse_cloudinary_id(cloudinary_id)
      search = Cloudinary::Search
        .expression("version=#{params[:version]} AND public_id=#{params[:public_id]}")
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

      main_image = image_metadata["url"] # http://res.cloudinary.com/ddoadcjjl/image/upload/v1652280851/test/office_chair.jpg
      thumb_120 = main_image.sub('upload', 'upload/a_0,c_fill,fl_progressive,h_120,w_120')
      thumb_300 = main_image.sub('upload', 'upload/a_0,c_fill,fl_progressive,h_300,w_300')

      # main_image => 'test/office_chair.jpg'
      # E.g. 'test/office_chair-120x120.jpg'
      # thumb_300 => 'test/office_chair-300x300.jpg'
      image_filenames = {
        main_image => cloudinary_id,
        thumb_120 => cloudinary_id.sub(/\.([^\.]+)$/, '-120x120.\1'),
        thumb_300 => cloudinary_id.sub(/\.([^\.]+)$/, '-300x300.\1')
      }

      # Download main image and thumbnails from Cloudinary and upload to Azure
      image_filenames.each do |cloudinary_url, blob_filename|
        content_type = nil
        image_content = nil
        ::URI.open(cloudinary_url, 'rb') do |file|
          content_type = file.content_type
          image_content = file.read
        end
        azure_client.create_block_blob('images', blob_filename, image_content, { content_type: content_type })
      end

      # update database and delete image on Cloudinary
      image.update_columns(cloudinary_id: "azure-#{cloudinary_id}")
      if (Image.where(cloudinary_id: cloudinary_id).size == 0)
        response = Cloudinary::Api.delete_resources(params[:public_id])
        result = response["deleted"][params[:public_id]]
        if (result == "deleted")
          log("Image successfully deleted from Cloudinary: #{params[:public_id]}")
        else
          log("Error '#{result}' when deleting image from Cloudinary: #{params[:public_id]}")
        end
      end
    end

    private

    # parse_cloudinary_id("1652280851/test/office_chair.jpg")
    # returns: { version: "1652280851", public_id: "test/office_chair" }
    def parse_cloudinary_id(cloudinary_id)
      { version: cloudinary_id.split('/')[0],
        public_id: cloudinary_id.split('/').drop(1).join('/').sub(/\.[^\.]+$/, '') }
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
