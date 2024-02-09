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
  #   > require 'open-uri'; require 'goodcity/image_archiver'
  #   > Goodcity::ImageArchiver.new(min_age: Date.parse('2018-11-30')).process_dispatched_packages
  #   > Goodcity::ImageArchiver.new.process_images(package.images)
  #   > Goodcity::ImageArchiver.new.process_images(offer.images)
  #   > Goodcity::ImageArchiver.new.process_dispatched_packages
  #   > Goodcity::ImageArchiver.new.process_archived_offers
  #   > ImageArchiveJob.perform_later(image_ids)
  #
  class ImageArchiver

    def initialize(options = {})
      # defaults
      @options = { min_age: 2.years.ago }.merge(options)
    end

    # An entry point for archiving images
    # - check that all related packages have 0 quantity in stock
    # - check that all related offers are closed or cancelled
    # 
    def process_images(images)
      images = [images].flatten.uniq.compact
      cloudinary_ids = images.map(&:cloudinary_id).uniq.compact

      cloudinary_ids.each do |cloudinary_id|

        # Assertion: Image is related to packages that all have 0 quantity in stock
        packages_in_stock = Package
          .joins("JOIN images ON images.imageable_id=packages.id AND images.imageable_type='Package'")
          .where("images.cloudinary_id" => cloudinary_id)
          .where.not(on_hand_quantity: 0).any?
        if packages_in_stock
          log("Skipping #{cloudinary_id} - not all related packages are fully dispatched.")
          next
        end

        # Assertion: Image is related to offers that are all closed or cancelled
        not_closed_or_cancelled_offers = Offer
          .joins("JOIN items ON items.offer_id=offers.id")
          .joins("JOIN images ON images.imageable_id=items.id AND images.imageable_type='Item'")
          .where("images.cloudinary_id" => cloudinary_id)
          .where("offers.state NOT IN (?)", ['closed', 'cancelled']).any?

        if not_closed_or_cancelled_offers
          log("Skipping #{cloudinary_id} - not all related offers are closed or cancelled.")
          next
        end

        # Just finding 1 instance will move all the others
        image = Image.find_by_cloudinary_id(cloudinary_id)
        move_to_azure_storage(image)

      end
    end

    # Criteria for archiving images on packages:
    #   - package has no available quantity
    #   - images are not already archived
    #   - package has not been updated recently
    #   - package does NOT belong to an offer that is still open (closed or cancelled)
    def process_dispatched_packages

      images = Image
        .joins("JOIN packages ON images.imageable_id=packages.id AND images.imageable_type='Package'")
        .where("packages.on_hand_quantity = 0")
        .where.not("images.cloudinary_id LIKE ?", "#{Image::AZURE_IMAGE_PREFIX}%")
        .where("packages.updated_at < ?", @options[:min_age].to_s(:db))
        .order('packages.updated_at')

      image_ids_to_exclude = Image.where(id: images.pluck('id'))
        .joins("JOIN packages ON images.imageable_id=packages.id AND images.imageable_type='Package'")
        .joins("JOIN items ON items.id=packages.item_id")
        .joins("JOIN offers ON offers.id=items.offer_id")
        .where('NOT offers.state IN (?)', ['closed', 'cancelled'])
        .pluck('id')
      result = images.where.not(id: image_ids_to_exclude)

      process_images(images)
    end

    # Criteria for archiving images on offers
    #  (This is necessary because some offers never turn into packages and hence the images are never archived.)
    #  - offer has been closed or cancelled
    #  - images are not already archived
    #  - offer has not been updated recently
    #  - offer doesn't have any packages (if it does then process_dispatched_packages will take care of it)
    def process_archived_offers
      images = Image
        .joins("JOIN items ON images.imageable_id=items.id AND images.imageable_type='Item'")
        .joins("JOIN offers ON offers.id=items.offer_id")
        .where("offers.state IN (?)", ['closed', 'cancelled'])
        .where.not("images.cloudinary_id LIKE ?", "#{Image::AZURE_IMAGE_PREFIX}%")
        .where("offers.updated_at < ?", @options[:min_age].to_s(:db))
        .where("NOT EXISTS (SELECT 1 FROM packages WHERE packages.item_id=items.id)")
        .order('offers.updated_at')

      process_images(images)
    end

    private

    #
    # The main algorithm
    # 1. Find the image on Cloudinary
    # 2. Download full size and thumbnails
    # 3. Upload to Azure storage
    # 4. Update all Image database entries (with the same Cloudinary id) with Image::AZURE_IMAGE_PREFIX to indicate that the image is archived
    #      This means if there is more than one image with the same cloudinary_id, they will all be moved.
    def move_to_azure_storage(image)
      cloudinary_id = image.cloudinary_id # 1652280851/test/office_chair.jpg
      if cloudinary_id.starts_with?(Image::AZURE_IMAGE_PREFIX)
        log("Image has already been transferred to Azure Storage: #{cloudinary_id}")
        return
      end

      search = Cloudinary::Search
        .expression("public_id=#{image.cloudinary_id_public_id}")
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
      # E.g. { "http://res.cloudinary.com/ddoadcjjl/image/upload/a_0/v1652280851/test/office_chair.jpg" => "test/office_chair.jpg", 
      #        "http://res.cloudinary.com/ddoadcjjl/image/upload/a_0,c_fill,fl_progressive,w_300,h_300/v1652280851/test/office_chair.jpg" => "test/office_chair-300x300.jpg"}
      image_cloudinary_url = image_metadata["secure_url"]
      image_mappings = { image_cloudinary_url.sub('upload', "upload/a_#{image.angle || 0}") => cloudinary_id }
      Image::AZURE_THUMBNAILS.each do |thumb|
        thumb_cloudinary_url = image_cloudinary_url.sub('upload', "upload/a_#{image.angle || 0},c_fill,fl_progressive,w_#{thumb[:width]},h_#{thumb[:height]}")
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

      # Update all instances of the image in the database and delete image on Cloudinary
      Image.where(cloudinary_id: image.cloudinary_id).update(cloudinary_id: "#{Image::AZURE_IMAGE_PREFIX}#{cloudinary_id}")
      public_id = image.cloudinary_id_public_id
      response = Cloudinary::Api.delete_resources(public_id)
      result = response["deleted"][public_id]
      if (result == "deleted")
        log("Image successfully deleted from Cloudinary: #{public_id}")
      else
        log("Error '#{result}' when deleting image from Cloudinary: #{public_id}")
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
