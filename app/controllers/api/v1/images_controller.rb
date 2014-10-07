module Api::V1
  class ImagesController < Api::V1::ApiController

    resource_description do
      short 'Generate image signature for Cloudinary service.'
      formats ['json']
      error 401, "Unauthorized"
      error 500, "Internal Server Error"
    end

    def_param_group :image do
      param :image, Hash do
        param :order, Integer, desc: "Not yet used"
        param :image_id, String, desc: "id of image uploaded to cloudinary"
        param :favourite, [true, false], desc: "This image will be used as default image for item."
        param :parent_type, String, desc: "Image belongs to? (polymorphic relationship like 'Item' or 'User')"
        param :parent_id, Integer
      end
    end

    api :GET, '/v1/images/generate_signature', "Generate image signature for Cloudinary service."
    def generate_signature
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
