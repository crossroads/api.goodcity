namespace :cloudinary do
  # tag value can be "development"/"staging"/"offer_#{id}"/
  # list of comma seperated tags: "offer_163, offer_164"
  # rake cloudinary:delete tag=development
  desc 'Clean cloudinary images by tag (rake cloudinary:delete tag=development)'
  task delete: :environment do
    if ENV['tag']
      tag_names = ENV['tag'].split(",").map(&:strip)
      tag_names.each do |tag|
        response = Cloudinary::Api.delete_resources_by_tag(tag)
        puts "Deleted #{response["deleted"].count} images with tag #{tag}."
      end
    end
  end

  desc "List cloudinary tags"
  task list_tags: :environment do
    tags = []
    next_cursor = nil
    is_next_cursor = true
    while is_next_cursor do
      list = Cloudinary::Api.tags(max_results: 500, next_cursor: next_cursor)
      tags << list["tags"]
      next_cursor = list[:next_cursor]
      is_next_cursor = !next_cursor.nil?
    end
    puts tags.uniq.compact
  end

  desc "Delete image records with broken images"
  task purge: :environment do
    Rails.logger.info(class: self.class.name, msg: "Searching for broken images...")
    count = 0;
    Image
      .find_each do |im|
        if image_has_been_deleted(im)
          Rails.logger.info(class: self.class.name, msg: "Cloudinary image was deleted", cloudinary_id: im.cloudinary_id, image_id: im.id)
          im.destroy
        end
        count = count + 1
        Rails.logger.info(class: self.class.name, msg: "#{count} images processed...") if count % 100 == 0
      end
  end

  MAX_SIZE_MB = 1
  MAX_SIZE_BYTES = MAX_SIZE_MB * 1024 * 1024
  MAX_SIZE = 1920
  OPTIMIZE_PAGE_SIZE = 500

  desc "Optimize image sizes"
  task optimize: :environment do
    Dir.mktmpdir do |dir|
      response = Cloudinary::Search
        .expression("resource_type:image AND bytes>#{MAX_SIZE_MB}m AND (width > #{MAX_SIZE} OR height > #{MAX_SIZE})")
        .sort_by('bytes','desc')
        .max_results(OPTIMIZE_PAGE_SIZE)
        .execute

      images_to_resize = response['resources']
        .reject { |res| is_placeholder(res) }
        .select { |res| can_be_resized(res) }

      images_to_resize.each do |res|
        public_id = res['public_id']
        file_path = "#{dir}/#{public_id}"

        log(self, "Resizing image #{public_id}")
        open_file(file_path) do |fd|
          fd << open(scaled_url(res)).read
          Cloudinary::Uploader.upload(file_path, { public_id: public_id }) # Override existing one
        end
      end

      count_left = response['total_count'] - response['resources'].length
      log(self, "Done, #{count_left} images can still be resized")
    rescue Exception => e
      Rails.logger.info(class: self.class.name, msg: e)
    end
  end

  #
  # ---- HELPERS
  #

  def log(parent, msg)
    puts msg
    Rails.logger.info(class: parent.class.name, msg: msg)
  end

  def is_portrait(res)
    res['height'] > res['width']
  end

  #
  # Will return true if an image has been deleted and cloudinary has
  # replaced it with a placeholder
  #
  def is_placeholder(res)
    res['placeholder'].present?
  end

  #
  # Checks whether a resize is possible
  #
  def can_be_resized(res)
    res['bytes'] > MAX_SIZE_BYTES && (
      is_portrait(res) ?
        res['height'] > MAX_SIZE :
        res['width'] > MAX_SIZE
    )
  end

  #
  # Return the cloudinary URL scaled to 'target_size'
  # 'target_size' applies to either width or height depending on the orientation
  #
  def scaled_url(res, target_size = MAX_SIZE)
    size_token = is_portrait(res) ?
      "h_#{target_size}" :
      "w_#{target_size}"
    res['url'].sub(/\/image\/upload\//, "/image/upload/#{size_token},c_scale/")
  end

  #
  # Similar to the native open(), but will create the required
  # subfolders if required
  #
  def open_file(file_path, &block)
    folder_path = begin
      path = file_path.split('/')
      path.pop()
      path
    end

    FileUtils.mkdir_p folder_path.join('/') if folder_path.length.positive?

    open(file_path, 'wb') do |file|
      block.call(file)
    end
  end

  #
  # Cloudinary ref: https://support.cloudinary.com/hc/en-us/articles/115000756771-How-to-check-if-an-image-exists-on-my-account-
  #
  def image_has_been_deleted(im)
    #
    # Remove the prepended version and the image extension
    # 1557819448/y1nxuenyyvix7gw3dyuy.jpg -> y1nxuenyyvix7gw3dyuy
    #
    trimmed_id = im.cloudinary_id
      .sub(/^\d+\//, '')
      .sub(/(\.jpg|\.jpeg\.png)$/, '')

    begin
      # Images that have been deleted are marked as 'placeholder'
      res = Cloudinary::Uploader.explicit(trimmed_id, :type => "upload")
      return res['resource_type'] == 'image' && is_placeholder(res)
    rescue
      # Something happened, we don't know for sure that the image has been deleted
      Rails.logger.info(class: self.class.name, msg: "Could not figure out the state of the image", cloudinary_id: im.cloudinary_id, image_id: im.id)
      return false
    end
  end
end
