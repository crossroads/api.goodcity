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
    it "returns 201", :show_in_doc do
      post :create, delivery: attributes_for(:delivery)
      expect(response.status).to eq(201)
    end
  end

  describe "PUT delivery/1" do
    let(:delivery) { create :delivery }
    before { generate_and_set_token(user) }
    it "owner can update", :show_in_doc do
      params = attributes_for(:delivery).merge({ gogovan_order_id: 1000001 })
      put :update, id: delivery.id, delivery: params
      expect(response.status).to eq(200)
      expect(delivery.reload.gogovan_order_id).to eq(1000001)
    end
  end

end
