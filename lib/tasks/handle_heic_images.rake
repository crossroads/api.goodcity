# rake goodcity:handle_heic_images

namespace :goodcity do
  task handle_heic_images: :environment do
    Image.where("cloudinary_id ilike ?", "%.heic%").find_each do |image|
      image.update(cloudinary_id: image.cloudinary_id.gsub(/heic/i, "jpg"))
    end
  end
end
