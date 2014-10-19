require 'rails_helper'

RSpec.describe Api::V1::ItemsController, type: :controller do

  let(:user)  { create :user_with_token }
  let(:offer) { create :offer, created_by: user }
  let(:image) { create :favourite_image }
  let(:item)  { create(:item, offer: offer, images: [image]) }
  let(:serialized_item) { Api::V1::ItemSerializer.new(item) }
  let(:serialized_item_json) { JSON.parse( serialized_item.to_json ) }
  let(:image_identifier1)  { Faker::Lorem.characters(10) }
  let(:image_identifier2)  { Faker::Lorem.characters(10) }
  let(:image_identifiers) { image_identifier1 << ',' << image_identifier2 }
  let(:item_params) { item.attributes.except("id").merge("image_identifiers" => image_identifiers, "favourite_image" => image_identifier2) }

  subject { JSON.parse(response.body) }

  describe "GET offers" do
    before { generate_and_set_token(user) }
    it "return serialized items", :show_in_doc do
      2.times{ create(:item, offer: offer) }
      get :index
      expect(response.status).to eq(200)
      expect( subject['items'].length ).to eq(2)
    end
  end

  describe "GET offers" do
    before { generate_and_set_token(user) }
    it "return items from offer", :show_in_doc do
      2.times { create(:item, offer: offer) }
      create(:offer, :with_items, items_count: 2, created_by: user)
      get :index, offer_id: offer.id
      expect(response.status).to eq(200)
      expect( subject['items'].length ).to eq(2)
    end

    it "fails to get items from an unauthorized offer", :show_in_doc do
      2.times { create(:item, offer: offer) }
      unauthorized_offer = create(:offer, :with_items, items_count: 2)
      get :index, offer_id: unauthorized_offer.id
      expect(response).not_to be_success
    end
  end

  describe "GET item" do
    before { generate_and_set_token(user) }
    it "return serialized item", :show_in_doc do
      get :show, id: item.id
      expect(response.status).to eq(200)
      expect(subject).to eq(serialized_item_json)
    end
  end

  describe "DELETE item/1" do
    before { generate_and_set_token(user) }
    it "should delete draft item", :show_in_doc do
      delete :destroy, id: item.id
      expect(response.status).to eq(200)
      expect(Item.only_deleted.count).to be_zero
      body = JSON.parse(response.body)
      expect(body).to eq( {} )
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
      expect(response.status).to eq(200)
      expect(item.reload.donor_description).to eq("Test item")
      expect(item.reload.images.count).to eq(1)
    end
  end

end
