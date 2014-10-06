require 'rails_helper'

RSpec.describe Api::V1::ItemsController, type: :controller do

  let(:user) { create :user_with_token }
  let(:offer) { create :offer, created_by: user }
  let(:image) { create :favourite_image }
  let(:item) { create(:item, offer: offer, images: [image]) }
  let(:serialized_item) { Api::V1::ItemSerializer.new(item) }
  let(:serialized_item_json) { JSON.parse( serialized_item.to_json ) }
  let(:item_params) { item.attributes.except("id").merge("image_identifiers" => Faker::Lorem.characters(10)) }

  describe "GET item" do
    before { generate_and_set_token(user) }
    it "returns 200" do
      get :show, id: item.id
      expect(response.status).to eq(200)
    end
    it "return serialized item", :show_in_doc do
      get :show, id: item.id
      body = JSON.parse(response.body)
      expect( body ).to eq(serialized_item_json)
    end
  end

  describe "DELETE item/1" do
    before { generate_and_set_token(user) }
    it "returns 200" do
      delete :destroy, id: item.id
      expect(response.status).to eq(200)
    end

    it "should delete draft item" do
      delete :destroy, id: item.id
      expect(Item.only_deleted.count).to be_zero
    end
  end

  describe "POST item/1" do
    before { generate_and_set_token(user) }
    it "returns 201", :show_in_doc do
      post :create, item: item_params
      expect(response.status).to eq(201)
    end
  end

  describe "PUT item/1" do
    before { generate_and_set_token(user) }
    it "owner can update", :show_in_doc do
      extra_params = { image_identifiers: Faker::Lorem.characters(10), donor_description: "Test item" }
      put :update, id: item.id, item: item_params.merge(extra_params)
      expect(item.reload.donor_description).to eq("Test item")
      expect(item.reload.images.count).to eq(1)
    end
  end

end
