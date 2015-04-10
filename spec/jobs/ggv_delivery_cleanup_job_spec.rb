require 'rails_helper'

RSpec.describe GgvDeliveryCleanupJob, type: :job do

  let!(:order) { create :gogovan_order, :with_delivery, :cancelled }

  it "should delete cancelled GGV order delivery" do
    expect {
      GgvDeliveryCleanupJob.new.perform(order.id)
    }.to change(Delivery, :count).by(-1)
  end

  describe "cancel delivery notification" do
    let!(:offer) { order.delivery.offer }

    it "should delete cancelled GGV order delivery" do
      expect {
        GgvDeliveryCleanupJob.new.perform(order.id)
      }.to change(offer.messages, :count).by(1)
    end
  end

end
