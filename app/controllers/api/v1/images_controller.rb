module Api
  module V1
    class ImagesController < Api::V1::ApiController
      load_and_authorize_resource :image, parent: false, except: [:generate_signature, :destroy]
      skip_authorization_check only: [:generate_signature, :destroy]

      resource_description do
        short 'Manage images for items in an offer.'
        formats ['json']
        error 401, "Unauthorized"
        error 500, "Internal Server Error"
      end

      def_param_group :image do
        param :image, Hash do
          param :cloudinary_id, String, desc: "The cloudinary image id for the image"
          param :favourite, [true, false, "true", "false"], desc: "This image will be used as default image for item"
          param :item_id, String, desc: "The offer item the image belongs to", allow_nil: true
        end
      end

      api :GET, '/v1/images/generate_signature', "Use this method to get an authentication signature in order to upload an image to the Cloudinary service."
      description " This API server does not accept direct image uploads. Instead, they should be sent directly to the Cloudinary service. Please refer to the {Cloudinary jQuery integration documentation}[http://cloudinary.com/documentation/jquery_integration] for further information."
      param :tags, String, desc: "csv list of tags to identify image", allow_nil: true
      def generate_signature
        unix_timestamp    = Time.now.to_i
        tags              = [Rails.env, params[:tags]].compact.join(",")
        serialized_params = "tags=#{tags}&timestamp=#{unix_timestamp}#{cloudinary_config['api_secret']}"
        signature         = Digest::SHA1.hexdigest(serialized_params)
        render json: {
          api_key:   cloudinary_config['api_key'],
          signature: signature,
          timestamp: unix_timestamp,
          tags: tags }.to_json
      end

      api :POST, '/v1/images', "Create an image"
      param_group :image
      def create
        @image.attributes = image_params
        if @image.save
          serialized_response(201)
        else
          render json: @image.errors, status: 422
        end
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
          serialized_response
        else
          render json: @image.errors, status: 422
        end
      end

      def show
        serialized_response
      end

      def delete_cloudinary_image
        key = params["cloudinary_id"].split("/").last.split(".").first rescue nil
        CloudinaryImageCleanupJob.perform_later(key) if key
        render nothing: true, status: 204
      end

      private

      def serialized_response(status = 200)
        if is_stock_app?
          render json: @image, serializer: StockitImageSerializer,
            status: status, root: :image
        else
          render json: @image, serializer: serializer, status: status
        end
      end

      def cloudinary_config
        Rails.application.secrets.cloudinary
      end

      def image_params
        assign_imageable
        params.require(:image).permit(:favourite,:cloudinary_id,:item_id, :angle,:imageable_type, :imageable_id)
      end

      def assign_imageable
        item_id = params["image"]["item_id"]
        if item_id.present?
          params["image"]["imageable_type"] = "Item"
          params["image"]["imageable_id"] = item_id
        end
      end

      def serializer
        Api::V1::ImageSerializer
      end
    end
  end
end
