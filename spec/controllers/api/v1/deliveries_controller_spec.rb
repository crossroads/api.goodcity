require 'rails_helper'

RSpec.describe Api::V1::DeliveriesController, type: :controller do

  let(:user) { delivery.offer.created_by }
  subject { JSON.parse(response.body) }
  before { generate_and_set_token(user) }

  describe "GET delivery with gogovan-transport" do
    let(:delivery) { create :gogovan_delivery }
    let(:serialized_delivery) { Api::V1::DeliverySerializer.new(delivery) }
    let(:serialized_delivery_json) { JSON.parse( serialized_delivery.to_json ) }

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

    it "return serialized delivery", :show_in_doc do
      get :show, id: delivery.id
      expect(response.status).to eq(200)
      expect(subject).to eq(serialized_delivery_json)
    end
  end

  describe "POST delivery/1" do
    let!(:offer) { create :offer, :reviewed }
    let(:user) { offer.created_by }

    it "returns 201", :show_in_doc do
      expect(controller).to receive(:delete_existing_delivery)
      post :create, delivery: attributes_for(:delivery).merge(offer_id: offer.id)
      expect(response.status).to eq(201)
    end
  end

  describe "PUT delivery/1 : update gogovan delivery" do
    let(:delivery) { create :gogovan_delivery, gogovan_order: nil }
    let(:gogovan_order) { create(:gogovan_order) }

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

    it "owner can update", :show_in_doc do
      put :update, id: delivery.id, delivery: crossroads_delivery.attributes.except(:id)
      expect(response.status).to eq(200)
      expect(delivery.reload.contact).to_not be_nil
    end
  end

  describe "PUT delivery/1 : update drop-off delivery" do
    let(:delivery) { create :drop_off_delivery, schedule: nil }
    let(:drop_off_delivery) { build(:drop_off_delivery) }

    it "owner can update", :show_in_doc do
      put :update, id: delivery.id, delivery: drop_off_delivery.attributes.except(:id)
      expect(response.status).to eq(200)
      expect(delivery.reload.schedule).to_not be_nil
    end
  end

  describe "DELETE delivery/1" do
    let(:delivery) { create :drop_off_delivery }

    it "returns 200", :show_in_doc do
      delete :destroy, id: delivery.id
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body).to eq( {} )
    end
  end

  describe "confirm_delivery" do
    let!(:gogovan_order) { create :gogovan_order }

    let(:offer) { create :offer, :reviewed, :with_transport }
    let(:delivery) { create :delivery, offer: offer }
    let(:district) { create :district }
    let(:ggv_transport) { create :gogovan_transport }

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
        "mobile" => user.mobile,
        "gogovanOptionId" => ggv_transport.id.to_s }
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

    describe "modify existing delivery" do

      let!(:old_delivery) { create :gogovan_delivery }
      let!(:old_offer)    { old_delivery.offer }
      let!(:old_contact_id)  { old_delivery.contact_id }
      let!(:old_ggv_id)  { old_delivery.gogovan_order_id }
      let!(:schedule) {
        { "scheduledAt" => "Fri Apr 17 2015 10:30:00 GMT+0530 (IST)",
          "slotName" => "10:30 AM" }
      }

      let!(:new_delivery) {
        { "id" => "#{old_delivery.id}",
          "deliveryType" => "Gogovan",
          "offerId" => "#{old_offer.id}",
          "scheduleAttributes" => schedule,
          "contactAttributes" => ggv_contact }
      }

      it "should confirm delivery by removing old associated records" do
        ActiveRecord::Base.connection.reset_pk_sequence!("schedules")
        expect(Gogovan).to receive(:cancel_order).with(old_delivery.gogovan_order.booking_id).and_return(200)
        expect(GogovanOrder).to receive(:book_order).with(user, ggv_order).and_return(gogovan_order)
        post :confirm_delivery, delivery: new_delivery, gogovanOrder: ggv_order

        expect(old_offer.reload.state).to eq("scheduled")
        expect(response.status).to eq(200)

        expect{
          Contact.find(old_contact_id)
        }.to raise_error(ActiveRecord::RecordNotFound)

        expect{
          GogovanOrder.find(old_ggv_id)
        }.to raise_error(ActiveRecord::RecordNotFound)

      end
    end

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

    it "should set new gogovan_transport option to offer" do
      expect(Gogovan).to receive_message_chain(:new, :confirm_order).and_return({"id"=> gogovan_order.booking_id})
      post :confirm_delivery, delivery: delivery_params, gogovanOrder: ggv_order

      expect(offer.reload.state).to eq("scheduled")
      expect(response.status).to eq(200)
      expect(offer.reload.gogovan_transport).to eq(ggv_transport)
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
