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

end
