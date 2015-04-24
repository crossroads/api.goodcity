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

  context "polling GGV order status" do

    it "successfully and update it" do
      expect(Gogovan).to receive(:order_status).with(order.booking_id).and_return(ggv_response)
      PollGogovanOrderStatusJob.new.perform(order.id)

      order.reload
      expect(order.status).to eq(ggv_response["status"])
      expect(order.price).to eq(ggv_response["price"])
      expect(order.driver_mobile).to eq(ggv_response["driver"]["phone_number"])
      expect(order.driver_name).to eq(ggv_response["driver"]["name"])
      expect(order.driver_license).to eq(ggv_response["driver"]["license_plate"])
    end

    context "with an error and re-raise it" do
      let(:ggv_response) { {:error => "API call failed"} }
      it do
        expect(Gogovan).to receive(:order_status).with(order.booking_id).and_return(ggv_response)
        expect{PollGogovanOrderStatusJob.new.perform(order.id)}.to raise_error(PollGogovanOrderStatusJob::ValueError, "API call failed")
      end
    end

  end

  it "should schedule itself for updated status" do
    expect(Gogovan).to receive(:order_status).with(order.booking_id).and_return(ggv_response)
    PollGogovanOrderStatusJob.new.perform(order.id)

    order.reload
    expect(enqueued_jobs.size).to eq(11)
    expect(enqueued_jobs.last[:job]).to eq(PollGogovanOrderStatusJob)
    expect(enqueued_jobs.last[:args]).to eq([order.id])
  end

  it "should delete empty GGV order if not belongs to any delivery" do
    expect(Gogovan).to receive_message_chain(:cancel_order).with(empty_order.booking_id).and_return(200)

    expect {
      PollGogovanOrderStatusJob.new.perform(empty_order.id)
    }.to change(GogovanOrder, :count).by(-1)
  end

  it "schedule delete delivery job if GGV order is cancelled" do
    expect(Gogovan).to receive(:order_status).with(active_order.booking_id).and_return(cancel_ggv_response)

    PollGogovanOrderStatusJob.new.perform(active_order.id)
    expect(enqueued_jobs.size).to eq(11)
    expect(enqueued_jobs.last[:job]).to eq(GgvDeliveryCleanupJob)
    expect(enqueued_jobs.last[:args]).to eq([active_order.id])
  end
end
