cloudinary_yml    = File.join(Rails.root.to_s, 'config/cloudinary.yml')
CLOUDINARY_CONFIG = YAML.load_file(cloudinary_yml)[Rails.env.to_s].symbolize_keys
CORS_FILE_PATH    = "#{Rails.public_path.to_s}/cloudinary_cors.html"
