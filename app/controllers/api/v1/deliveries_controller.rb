module Api
  module V1
    class DeliveriesController < Api::V1::ApiController
      load_and_authorize_resource :delivery, parent: false

      resource_description do
        short 'Get, create, and update deliveries.'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
        description <<-EOS
          == Delivery relationships
          [link:/doc/deliveries_relationship.png]
          Generated using
            gem install railroady
            railroady -s app/models/delivery.rb,app/models/gogovan_order.rb,app/models/schedule.rb,app/models/address.rb,app/models/offer.rb,app/models/contact.rb -M | dot -Tpng > deliveries.png
        EOS
      end

      def_param_group :delivery do
        param :delivery, Hash, required: true do
          param :offer_id, String, desc: "Id of offer to which delivery belongs."
          param :contact_id, String, allow_nil: true, desc: "Id of contact to which delivery belongs."
          param :schedule_id, String, allow_nil: true, desc: "Id of schedule to which delivery belongs."
          param :delivery_type, ["Alternate", "Drop Off", "Gogovan"], desc: "Delivery type.", allow_nil: true
          param :start, String, allow_nil: true, desc: "Not yet used"
          param :finish, String, allow_nil: true, desc: "Not yet used"
        end
      end

      api :POST, '/v1/deliveries', "Create a delivery"
      param_group :delivery
      def create
        delete_existing_delivery
        @delivery.attributes = delivery_params
        if @delivery.save
          render json: @delivery, serializer: serializer, status: 201
        else
          render_errors
        end
      end

      api :GET, '/v1/deliveries/1', "Get a delivery"
      def show
        render json: @delivery, serializer: serializer
      end

      api :PUT, '/v1/deliveries/1', "Update a delivery"
      param_group :delivery
      def update
        if @delivery.update(delivery_params)
          render json: @delivery, serializer: serializer
        else
          render_errors
        end
      end

      api :DELETE, "/v1/deliveries/1", "Delete delivery"
      def destroy
        @delivery.destroy
        render json: {}
      end

      api :POST, '/confirm_delivery', "Confirm Delivery with address, contact and schedule details"
      param :delivery, Hash, required: true do
        param :id, String, 'Id of Delivery'
        param :deliveryType, ['Gogovan', 'Drop Off', 'Alternate'], desc: "Delivery type."
        param :offerId, String, 'Id of Offer'
        param :scheduleAttributes, Hash, required: true do
          param :zone, String
          param :resource, String
          param :scheduledAt, String, required: true, desc: "Date scheduled for delivery pick-up"
          param :slot, String
          param :slotName, String, desc: "Time slot booked for delivery pick-up"
        end
        param :contactAttributes, Hash do
          param :name, String
          param :mobile, String
          param :addressAttributes, Hash do
            param :street, String
            param :flat, String
            param :building, String
            param :districtId, String
            param :addressType, ['collection']
          end
        end
      end
      param :gogovanOrder, Hash do
        param :pickupTime, String, desc: "Time scheduled for delivery pick-up"
        param :districtId, String, desc: "Id of District"
        param :gogovanOptionId, String, desc: "Id of gogovan transport option"
        param :needEnglish, String, desc: "Need english-speaking GGV Driver"
        param :needCart, String, desc: "Need carts"
        param :needCarry, String, desc: ""
        param :offerId, String, desc: "Id of Offer"
        param :name, String
        param :mobile, String
      end
      def confirm_delivery
        return unless validate_schedule

        @delivery = Delivery.find_by(id: params["delivery"]["id"])
        @delivery.delete_old_associations
        @delivery.gogovan_order = GogovanOrder.book_order(current_user,
          order_params) if params["gogovanOrder"]
        if @delivery && @delivery.update(get_delivery_details)
          render json: @delivery, serializer: serializer
        else
          render_errors
        end
      end

      private

      def render_errors
        render json: @delivery.errors, status: 422
      end

      def delivery_params
        params.require(:delivery).permit(:start, :finish, :offer_id,
          :contact_id, :schedule_id, :delivery_type, :gogovan_order_id)
      end

      def delivery_attrs
        params.require(:delivery).permit!
      end

      def order_params
        params.require(:gogovanOrder).permit(:pickupTime, :districtId,
          :needEnglish, :needCart, :needCarry, :offerId, :name, :mobile,
          :gogovanOptionId)
      end

      def serializer
        Api::V1::DeliverySerializer
      end

      def delete_existing_delivery
        offer_id = params[:delivery][:offer_id]
        Delivery.where(offer_id: offer_id).each do |delivery|
          authorize!(:destroy, delivery)
        delivery.destroy
        end
      end

      def get_delivery_details
        params["delivery"] = get_hash(delivery_attrs.to_h)
        params.require(:delivery).permit(:start, :finish, :offer_id,
          :contact_id, :schedule_id, :delivery_type, :gogovan_order_id,
          schedule_attributes: schedule_attributes,
          contact_attributes: [:name, :mobile,
            address_attributes: address_attributes])
      end

      def scheduled_date
        scheduled_at = get_delivery_details.dig(:schedule_attributes, :scheduled_at)
        return nil unless scheduled_at.present?
        begin
          Date.parse(scheduled_at)
        rescue ArgumentError
          nil
        end
      end

      def validate_schedule
        if scheduled_date.blank?
          render_error(I18n.t('schedule.bad_date'))
          return false
        end

        if Holiday.is_holiday?(scheduled_date)
          render_error(I18n.t('schedule.holiday_conflict', date: scheduled_date));
          return false
        end

        true
      end

      def address_attributes
        %i[address_type district_id street flat building]
      end

      def schedule_attributes
        %i[scheduled_at slot_name zone resource slot]
      end

      def get_hash(object)
        Hash[
          object.map do |k, v|
            [k.underscore, v.is_a?(Hash) ? get_hash(v) : v]
          end
        ]
      end
    end
  end
end
