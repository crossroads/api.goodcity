require 'rails_helper'

RSpec.describe Api::V1::ItemsController, type: :controller do

  let(:user)  { create :user_with_token }
  let(:offer) { create :offer, created_by: user }
  let(:image) { create :image, favourite: true }
  let(:item)  { create(:item, offer: offer, images: [image]) }
  let(:serialized_item) { Api::V1::ItemSerializer.new(item) }
  let(:serialized_item_json) { JSON.parse( serialized_item.to_json ) }
  let(:item_params) { item.attributes.except("id") }

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
      extra_params = { donor_description: "Test item" }
      put :update, id: item.id, item: item_params.merge(extra_params)
      expect(response.status).to eq(200)
      expect(item.reload.donor_description).to eq("Test item")
    end
  end

end
