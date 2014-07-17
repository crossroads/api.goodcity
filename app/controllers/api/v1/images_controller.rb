module Api::V1
  class ImagesController < Api::V1::ApiController

    def generate_cloudinary_signature
      unix_timestamp    = Time.now.to_i
      serialized_params = "callback=#{CORS_FILE_PATH}&timestamp=#{unix_timestamp}#{CLOUDINARY_CONFIG[:api_secret]}"
      signature         = Digest::SHA1.hexdigest(serialized_params)
      render json: {
        api_key:   CLOUDINARY_CONFIG[:api_key],
        callback:  CORS_FILE_PATH,
        signature: signature,
        timestamp: unix_timestamp }.to_json
    end

  end
end
