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
    let(:item)  { create :item, offer: offer, state: "draft" }

    it "should delete draft item", :show_in_doc do
      delete :destroy, id: item.id
      expect(response.status).to eq(200)
      expect(Item.only_deleted.count).to be_zero
      body = JSON.parse(response.body)
      expect(body).to eq( {} )
    end

    it 'should not delete the last item if offer not draft' do
      offer = create :offer, created_by: user, state: 'reviewed'
      item = create :item, offer: offer, state: "accepted"
      delete :destroy, id: item.id
      expect(response.status).to eq(422)
      body = JSON.parse(response.body)
      expect(body['errors']).to eq('Cannot delete the last item of a non-draft offer')
    end

    it 'should revert to under_review offer state if deleted item is last accepted item' do
      offer = create :offer, created_by: user, state: 'reviewed'
      item = create :item, offer: offer, state: 'accepted'
      create :item, offer: offer, state: 'rejected'

      delete :destroy, id: item.id
      expect(response.status).to eq(200)
      offer.reload
      expect(offer.state).to eq('under_review')
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
