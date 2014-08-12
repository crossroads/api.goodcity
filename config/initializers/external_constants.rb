CLOUDINARY_CONFIG = {
  cloud_name: ENV['CLOUDINARY_CLOUD_NAME'],
  api_key: ENV['CLOUDINARY_API_KEY'],
  api_secret: ENV['CLOUDINARY_API_SECRET'],
  enhance_image_tag: true,
  static_image_support: Rails.env.production?
}

CORS_FILE_PATH    = "#{Rails.public_path.to_s}/cloudinary_cors.html"
