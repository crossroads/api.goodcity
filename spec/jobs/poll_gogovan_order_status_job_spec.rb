require 'rails_helper'

RSpec.describe PollGogovanOrderStatusJob, type: :job do

  let(:order) { create :gogovan_order, :with_delivery }
  let!(:empty_order) { create :gogovan_order }
  let(:active_order) { create :gogovan_order, :with_delivery, :active }

  let(:response) {
    { "id" => 260,
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

  let(:ggv_response) { response.merge({ "status" => "active" }) }
  let(:cancel_ggv_response) { response.merge({ "status" => "cancelled" }) }

  it "should poll GGV order status and update it" do
    expect(Gogovan).to receive_message_chain(:new, :get_status).with(order.booking_id).and_return(ggv_response)
    PollGogovanOrderStatusJob.new.perform(order.id)

    order.reload
    expect(order.status).to eq(ggv_response["status"])
    expect(order.price).to eq(ggv_response["price"])
    expect(order.driver_mobile).to eq(ggv_response["driver"]["phone_number"])
    expect(order.driver_name).to eq(ggv_response["driver"]["name"])
    expect(order.driver_license).to eq(ggv_response["driver"]["license_plate"])
  end

  it "should schedule itself for updated status" do
    expect(Gogovan).to receive_message_chain(:new, :get_status).with(order.booking_id).and_return(ggv_response)
    PollGogovanOrderStatusJob.new.perform(order.id)

    order.reload
    expect(enqueued_jobs.size).to eq(1)
    expect(enqueued_jobs[0][:job]).to eq(PollGogovanOrderStatusJob)
    expect(enqueued_jobs[0][:args]).to eq([order.id])
  end

  it "should delete empty GGV order if not belongs to any delivery" do
    expect(Gogovan).to receive_message_chain(:cancel_order).with(empty_order.booking_id)

    expect {
      PollGogovanOrderStatusJob.new.perform(empty_order.id)
    }.to change(GogovanOrder, :count).by(-1)
  end

  it "schedule delete delivery job if GGV order is cancelled" do
    expect(Gogovan).to receive_message_chain(:new, :get_status).with(active_order.booking_id).and_return(cancel_ggv_response)

    PollGogovanOrderStatusJob.new.perform(active_order.id)
    expect(enqueued_jobs.size).to eq(1)
    expect(enqueued_jobs[0][:job]).to eq(GgvDeliveryCleanupJob)
    expect(enqueued_jobs[0][:args]).to eq([active_order.id])
  end
end
