namespace :goodcity do
  # tag value can be "development"/"staging"/"offer_#{id}"/
  # list of comma seperated tags: "offer_163, offer_164"
  # rake goodcity:clean_cloudinary_images tag=development
  desc 'clean cloudinary images'
  task clean_cloudinary_images: :environment do
    if ENV['tag']
      tag_names = ENV['tag'].split(",").map(&:strip)
      tag_names.each do |tag|
        response = Cloudinary::Api.delete_resources_by_tag(tag)
        puts "Deleted #{response["deleted"].count} images with tag #{tag}."
      end
    end
  end
end
