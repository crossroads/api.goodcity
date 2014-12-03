module Api::V1
  class ImagesController < Api::V1::ApiController
    load_and_authorize_resource :image, parent: false, :except => [:generate_signature, :destroy]
    skip_authorization_check only: [:generate_signature, :destroy]

    resource_description do
      short 'Generate an image signature for Cloudinary service'
      formats ['json']
      error 401, "Unauthorized"
      error 500, "Internal Server Error"
    end

    def_param_group :image do
      param :image, Hash do
        param :cloudinary_id, String, desc: "The cloudinary image id for the image"
        param :favourite, [true, false], desc: "This image will be used as default image for item"
        param :item_id, String, desc: "The offer item the image belongs to"
      end
    end

    api :GET, '/v1/images/generate_signature', "Use this method to get an authentication signature in order to upload an image to the Cloudinary service."
    description " This API server does not accept direct image uploads. Instead, they should be sent directly to the Cloudinary service. Please refer to the {Cloudinary jQuery integration documentation}[http://cloudinary.com/documentation/jquery_integration] for further information."
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

    api :POST, '/v1/images', "Create an image"
    param_group :image
    def create
      @image.attributes = image_params
      if @image.save
        render json: @image, serializer: serializer, status: 201
      else
        render json: @image.errors.to_json, status: 422
      end
    end

    api :GET, '/v1/images', "List all images"
    param :ids, Array, of: Integer, desc: "Filter by images ids e.g. ids = [1,2,3,4]"
    def index
      @images = @images.find(params[:ids].split(",")) if params[:ids].present?
      render json: @images, each_serializer: serializer
    end

    api :GET, '/v1/images/1', "List an image"
    def show
      render json: @image, serializer: serializer
    end

    api :DELETE, '/v1/images/1', "Delete an image"
    def destroy
      @image = Image.find_by_id(params[:id])
      if @image
        authorize! :destroy, @image
        @image.destroy
      end
      render json: {}
    end

    api :PUT, '/v1/images/1', "Update an image"
    param_group :image
    def update
      if @image.update_attributes(image_params)
        if @image.favourite
          @image.item.images.where.not(id: @image.id).update_all(favourite: false)
        end
        render json: @image, serializer: serializer
      else
        render json: @image.errors.to_json, status: 422
      end
    end

    private

    def cloudinary_config
      Rails.application.secrets.cloudinary
    end

    def callback
      host = request.original_url.gsub(request.fullpath, '')
      "#{host}/cloudinary_cors.html"
    end

    def image_params
      params.require(:image).permit(:favourite,:cloudinary_id,:item_id)
    end

    def serializer
      Api::V1::ImageSerializer
    end
  end
end
