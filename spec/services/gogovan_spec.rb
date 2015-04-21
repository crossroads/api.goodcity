require "rails_helper"

describe Gogovan do

  let(:user)        { create :user }
  let(:name)        { "John Roy" }
  let(:mobile)      { "+85210002000" }
  let(:pickupTime)  { Time.now.to_s }
  let(:needEnglish) { "true" }
  let(:needCart)    { "true" }
  let(:needCarry)   { "true" }
  let(:districtId)  { (create :district).id }
  let(:vehicle)     { "van" }
  let(:offer_id)    { create(:delivery).offer.id }

  let(:attributes) {
    {
      'name' => name,
      'mobile' => mobile,
      'pickupTime' => pickupTime,
      'needEnglish' => needEnglish,
      'needCarry' => needCarry,
      'needCart' => needCart,
      'districtId' => districtId,
      'vehicle' => vehicle,
      'offerId' => offer_id,
      'ggv_uuid' => "1234"
    }
  }

  let(:gogovan_order) { Gogovan.new(user, attributes) }

  context "initialization" do

    it "user" do
      expect(gogovan_order.user).to eql(user)
    end
    it "name" do
      expect(gogovan_order.name).to eql(name)
    end
    it "mobile" do
      expect(gogovan_order.mobile).to eql(mobile)
    end
    it "pickupTime" do
      expect(gogovan_order.time).to eql(pickupTime)
    end
    it "needEnglish" do
      expect(gogovan_order.need_english).to eql(needEnglish)
    end
    it "needCarry" do
      expect(gogovan_order.need_carry).to eql(needCarry)
    end
    it "needCart" do
      expect(gogovan_order.need_cart).to eql(needCart)
    end
    it "districtId" do
      expect(gogovan_order.district_id).to eql(districtId)
    end
    it "vehicle" do
      expect(gogovan_order.vehicle).to eql(vehicle)
    end
  end

  describe 'initiate gogovan order' do
    it do
      order_object = gogovan_order.initiate_order
      expect(order_object.params).to eq(gogovan_order.send(:order_attributes))
    end
  end

  describe 'ggv driver notes' do
    it do
      notes = gogovan_order.send(:ggv_driver_notes)
      expect(notes).to include("Ensure you deliver all the items listed: See details")
    end
  end
end
