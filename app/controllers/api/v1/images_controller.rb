module Api::V1
  class ImagesController < Api::V1::ApiController

    resource_description do
      short 'Generate cloudinary signature'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :image do
      param :image, Hash do
        param :order, Integer, desc: "Not yet used"
        param :image_id, String, desc: "id of image uploaded to cloudinary"
        param :favourite, [true, false], desc: "This image will be used as main image to describe item."
        param :parent_type, String, desc: "Image belongs to? (polymorphic relationship like 'Item' or 'User')"
        param :parent_id, Integer
      end
    end

    api :GET, '/v1/generate_cloudinary_signature', "Generate cloudinary signature for session to upload images to cloudinary"
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
