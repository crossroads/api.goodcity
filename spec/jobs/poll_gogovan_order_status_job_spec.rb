require 'rails_helper'

RSpec.describe PollGogovanOrderStatusJob, type: :job do

  let(:order) { create :gogovan_order, :with_delivery }
  let(:ggv_response) {
    { "id" => 260,
      "status" => "active",
      "name" => "Cecile Toy",
      "phone_number" => "1-060-838-1161",
      "price" => 80.0,
      "driver" =>  {
        "id" => 100,
        "phone_number" => "92011901",
        "name" => "Tessie McClure I",
        "license_plate" => "AS5154"
      }
    }
  }

  it "should receive a order and call airbrake" do
    expect(Gogovan).to receive_message_chain(:new, :get_status).with(order.booking_id).and_return(ggv_response)
    PollGogovanOrderStatusJob.new.perform(order.id)

    order.reload
    expect(order.status).to eq(ggv_response["status"])
    expect(order.price).to eq(ggv_response["price"])
    expect(order.driver_mobile).to eq(ggv_response["driver"]["phone_number"])
    expect(order.driver_name).to eq(ggv_response["driver"]["name"])
    expect(order.driver_license).to eq(ggv_response["driver"]["license_plate"])
  end
end
