module Api::V1
  class ImagesController < Api::V1::ApiController

    def generate_cloudinary_signature
      unix_timestamp    = Time.now.to_i
      serialized_params = "callback=#{callback}&timestamp=#{unix_timestamp}#{cloudinary_config['api_secret']}"
      signature         = Digest::SHA1.hexdigest(serialized_params)
      render json: {
        api_key:   cloudinary_config['api_key'],
        callback:  callback,
        signature: signature,
        timestamp: unix_timestamp }.to_json
    end

    private

    def cloudinary_config
      Rails.application.secrets.cloudinary
    end

    def callback
      host = request.original_url.gsub(request.fullpath, '')
      "#{host}/cloudinary_cors.html"
    end

  end
end
