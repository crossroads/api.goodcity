require 'rails_helper'

RSpec.describe Api::V1::DeliveriesController, type: :controller do

  let(:user) { create :user_with_token }
  subject { JSON.parse(response.body) }

  describe "GET delivery with gogovan-transport" do
    let(:delivery) { create :gogovan_delivery }
    let(:serialized_delivery) { Api::V1::DeliverySerializer.new(delivery) }
    let(:serialized_delivery_json) { JSON.parse( serialized_delivery.to_json ) }

    before { generate_and_set_token(user) }
    it "return serialized delivery", :show_in_doc do
      get :show, id: delivery.id
      expect(response.status).to eq(200)
      expect(subject).to eq(serialized_delivery_json)
    end
  end

  describe "GET delivery with drop-off-transport" do
    let(:delivery) { create :drop_off_delivery }
    let(:serialized_delivery) { Api::V1::DeliverySerializer.new(delivery) }
    let(:serialized_delivery_json) { JSON.parse( serialized_delivery.to_json ) }

    before { generate_and_set_token(user) }
    it "return serialized delivery", :show_in_doc do
      get :show, id: delivery.id
      expect(response.status).to eq(200)
      expect(subject).to eq(serialized_delivery_json)
    end
  end

  describe "GET delivery with crossroads-transport" do
    let(:delivery) { create :crossroads_delivery }
    let(:serialized_delivery) { Api::V1::DeliverySerializer.new(delivery) }
    let(:serialized_delivery_json) { JSON.parse( serialized_delivery.to_json ) }

    before { generate_and_set_token(user) }
    it "return serialized delivery", :show_in_doc do
      get :show, id: delivery.id
      expect(response.status).to eq(200)
      expect(subject).to eq(serialized_delivery_json)
    end
  end

  describe "POST delivery/1" do
    before { generate_and_set_token(user) }
    let!(:offer) { create :offer, :reviewed }

    it "returns 201", :show_in_doc do
      post :create, delivery: attributes_for(:delivery).merge(offer_id: offer.id)
      expect(response.status).to eq(201)
    end

    context "for offer having delivery" do
      let!(:delivery) { create :drop_off_delivery }
      let!(:delivery_id) { delivery.id }

      it "should delete existing delivery" do
        post :create, delivery: delivery.attributes
        expect(response.status).to eq(201)

        expect{
          Delivery.find(delivery_id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "PUT delivery/1 : update gogovan delivery" do
    let(:delivery) { create :gogovan_delivery, gogovan_order: nil }
    let(:gogovan_order) { create(:gogovan_order) }
    before { generate_and_set_token(user) }

    it "owner can update", :show_in_doc do
      params = { gogovan_order_id: gogovan_order.id }
      put :update, id: delivery.id, delivery: params
      expect(response.status).to eq(200)
      expect(delivery.reload.gogovan_order_id).to eq(gogovan_order.id)
    end
  end

  describe "PUT delivery/1 : update crossroads delivery" do
    let(:delivery) { create :crossroads_delivery, contact: nil, schedule: nil }
    let(:crossroads_delivery) { build(:crossroads_delivery) }
    before { generate_and_set_token(user) }

    it "owner can update", :show_in_doc do
      put :update, id: delivery.id, delivery: crossroads_delivery.attributes.except(:id)
      expect(response.status).to eq(200)
      expect(delivery.reload.contact).to_not be_nil
    end
  end

  describe "PUT delivery/1 : update drop-off delivery" do
    let(:delivery) { create :drop_off_delivery, schedule: nil }
    let(:drop_off_delivery) { build(:drop_off_delivery) }
    before { generate_and_set_token(user) }

    it "owner can update", :show_in_doc do
      put :update, id: delivery.id, delivery: drop_off_delivery.attributes.except(:id)
      expect(response.status).to eq(200)
      expect(delivery.reload.schedule).to_not be_nil
    end
  end

  describe "DELETE delivery/1" do
    before { generate_and_set_token(user) }
    let(:delivery) { create :drop_off_delivery }

    it "returns 200", :show_in_doc do
      delete :destroy, id: delivery.id
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body).to eq( {} )
    end
  end

  describe "confirm_delivery" do
    before { generate_and_set_token(user) }
    let!(:gogovan_order) { create :gogovan_order }

    let(:offer) { create :offer, :reviewed, :with_transport }
    let(:delivery) { create :delivery, offer: offer }
    let(:district) { create :district }

    let(:ggv_schedule) {
      { "scheduledAt" => "Fri Apr 17 2015 10:30:00 GMT+0530 (IST)",
        "slotName" => "10:30 AM" }
    }

    let(:ggv_address) {
      { "addressType" => "collection", "districtId" => "#{district.id}" }
    }

    let(:ggv_contact) {
      { "name" => "David Dara51",
        "mobile" => "+85251111111",
        "addressAttributes" => ggv_address }
    }

    let(:ggv_order) {
      { "pickupTime" => "Fri Apr 17 2015 10:30:00 GMT+0530 (IST)",
        "districtId" => "#{district.id}",
        "needEnglish" => "true",
        "needCart" => "true",
        "needCarry" => "true",
        "offerId" => "#{offer.id}",
        "name" => user.first_name,
        "mobile" => user.mobile }
    }

    let(:delivery_params) {
      { "id" => "#{delivery.id}",
        "deliveryType" => "Gogovan",
        "offerId" => "#{offer.id}",
        "scheduleAttributes" => ggv_schedule,
        "contactAttributes" => ggv_contact }
    }

    let(:drop_off_delivery) {
      { "id" => "#{delivery.id}",
        "deliveryType" => "Drop Off",
        "offerId" =>  "#{offer.id}",
        "scheduleAttributes" => {
          "slot" => "2",
          "scheduledAt" => "Fri Apr 17 2015 00:00:00 GMT+0530 (IST)",
          "slotName" => "11AM-1PM"}
      }
    }

    let(:collection_address) {
      { "street" => "test3", "flat" => "test5", "building" => "test4", "districtId" => "#{district.id}", "addressType" => "collection" }
    }

    let(:collection_contact) {
      { "name" => "David Dara51",
        "mobile" => "+85251111111",
        "addressAttributes" =>  collection_address }
    }

    let(:collection_schedule) {
      { "zone" => "South",
        "resource" => "Truck C",
        "scheduledAt" => "Sun Apr 26 2015 11:26:47 GMT+0530 (IST)",
        "slot" => "4",
        "slotName" => "Evening,4pm-6pm" }
    }

    let(:collection_delivery) {
      { "id" => "#{delivery.id}",
        "deliveryType" => "Alternate",
        "offerId" => "#{offer.id}",
        "scheduleAttributes" => collection_schedule,
        "contactAttributes" => collection_contact }
    }

    it "should confirm delivery for gogovan option" do
      expect(GogovanOrder).to receive(:book_order).with(user, ggv_order).and_return(gogovan_order)
      post :confirm_delivery, delivery: delivery_params, gogovanOrder: ggv_order

      expect(delivery.reload.gogovan_order).to eq(gogovan_order)
      expect(offer.reload.state).to eq("scheduled")
      expect(response.status).to eq(200)

      serialized_delivery = Api::V1::DeliverySerializer.new(delivery)
      serialized_delivery_json = JSON.parse(serialized_delivery.to_json)
      expect(subject).to eq(serialized_delivery_json)
    end

    it "should confirm delivery for drop-off option" do
      post :confirm_delivery, delivery: drop_off_delivery

      expect(offer.reload.state).to eq("scheduled")
      expect(response.status).to eq(200)

      serialized_delivery = Api::V1::DeliverySerializer.new(delivery.reload)
      serialized_delivery_json = JSON.parse(serialized_delivery.to_json)
      expect(JSON.parse(response.body)).to eq(serialized_delivery_json)
    end

    it "should confirm delivery for collection option" do
      post :confirm_delivery, delivery: collection_delivery

      expect(offer.reload.state).to eq("scheduled")
      expect(response.status).to eq(200)

      serialized_delivery = Api::V1::DeliverySerializer.new(delivery.reload)
      serialized_delivery_json = JSON.parse(serialized_delivery.to_json)
      expect(JSON.parse(response.body)).to eq(serialized_delivery_json)
    end
  end

end
