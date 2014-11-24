module Api::V1
  class GogovanOrdersController < Api::V1::ApiController

    skip_authorization_check only: [:calculate_price, :confirm_order]

    def calculate_price
      order_details = {
        order: {
          name: current_user.full_name,
          phone_number: current_user.mobile,
          pickup_time: params["pickupTime"],
          vehicle: "van",
          locations: [[22.312516,114.217874,"Seaview Center, 139 Hoi Bun Road, Hong Kong"],[22.3741183,113.9927744, "Crossroads Foundation"]].to_json,
          extra_requirements: {
            need_english: params["needEnglish"],
            need_cart: params["needCart"],
            need_carry: params["needCarry"]
          }
        }
      }
      order = GoGoVanApi::Order.new(params: order_details)
      render json: order.price.to_json
    end

    def confirm_order
      details = params["gogovan_order"]
      order_details = {
        order: {
          name: current_user.full_name,
          phone_number: current_user.mobile,
          pickup_time: details["pickup_time"],
          vehicle: "van",
          locations: [[22.312516,114.217874,"Seaview Center, 139 Hoi Bun Road, Hong Kong"],[22.3741183,113.9927744, "Crossroads Foundation"]].to_json,
          extra_requirements: {
            need_english: details["need_english"],
            need_cart: details["need_cart"],
            need_carry: details["need_carry"]
          }
        }
      }
      order = GoGoVanApi::Order.new(params: order_details)
      book_order = order.book
      gogovan_order = GogovanOrder.create(status: "pending", booking_id: book_order['id'])
      render json: gogovan_order, serializer: serializer
    end

    private

    def serializer
      Api::V1::GogovanOrderSerializer
    end

  end
end
