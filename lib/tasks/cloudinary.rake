require 'nestful'

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
    Image
      .all
      .select { |im| image_has_been_deleted(im) }
      .each do |im|
        im.destroy
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
      return res['resource_type'] == 'image' && res['placeholder'].present?
    rescue
      # Something happened, we don't know for sure that the image has been deleted
      return false
    end
  end
end
