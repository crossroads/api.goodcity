module Api::V1
  class GogovanOrdersController < Api::V1::ApiController

    skip_authorization_check only: [:calculate_price, :confirm_order]

    def calculate_price
      order = initiate_order(params)
      render json: order.price.to_json
    end

    def confirm_order
      attributes = params_hash(params["gogovan_order"])
      book_order = initiate_order(attributes).book
      gogovan_order = GogovanOrder.save_booking(book_order['id'])
      render json: gogovan_order, serializer: serializer
    end

    private

    def initiate_order(attributes)
      order_details = order_attributes(attributes)
      GoGoVanApi::Order.new(params: order_details)
    end

    # hash with keys in lower-camelcase form
    def params_hash(params)
      Hash[params.map{|(k,v)| [k.camelize(:lower),v]}]
    end

    def serializer
      Api::V1::GogovanOrderSerializer
    end

    def order_attributes(order)
      {
        order: {
          name:           order["name"] || current_user.full_name,
          phone_number:   order["mobile"] || current_user.mobile,
          pickup_time:    order["pickupTime"],
          vehicle:        "van",
          locations:      District.location_json(order['districtId']),
          extra_requirements: {
            need_english: order["needEnglish"],
            need_cart:    order["needCart"],
            need_carry:   order["needCarry"]
          }
        }
      }
    end
  end
end
