module Api::V1
  class GogovanOrdersController < Api::V1::ApiController

    skip_authorization_check only: [:calculate_price]

    def calculate_price
      order_details = {
        order: {
          name: current_user.full_name,
          phone_number: current_user.mobile,
          pickup_time: params["pickup_time"],
          vehicle: "van",
          locations: [[22.312516,114.217874,"Seaview Center, 139 Hoi Bun Road, Hong Kong"],[22.3741183,113.9927744, "Crossroads Foundation"]],
          extra_requirements: {
            need_english: params["need_english"],
            need_cart: params["need_cart"],
            need_carry: params["need_carry"]
          }
        }
      }
      order = GoGoVanApi::Order.new(order_details)
      render json: order.price.to_json
    end

    def confirm_order
    end

  end
end
