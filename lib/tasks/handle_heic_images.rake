# rake goodcity:handle_heic_images

namespace :goodcity do
  task handle_heic_images: :environment do
    count = 0
    Image.where("cloudinary_id ilike ?", "%.heic%").find_each do |image|
      count += 1 if image.update(cloudinary_id: image.cloudinary_id.gsub(/heic/i, "jpg"))
    end
    message = "#{count} images updated converted jpg from heic"
    puts message
    Rails.logger.info(task: "handle_heic_images", msg: message)
  end
end
