require 'rails_helper'

RSpec.describe Api::V1::ItemsController, type: :controller do
  let(:user)  { create :user, :with_token, :with_can_manage_items_permission }
  let(:offer) { create :offer, created_by: user }
  let(:item)  { create(:item, offer: offer) }
  let(:serialized_item) { Api::V1::ItemSerializer.new(item).as_json }
  let(:serialized_item_json) { JSON.parse( serialized_item.to_json ) }
  let(:item_params) { item.attributes.except("id") }
  let(:parsed_body) { JSON.parse(response.body) }

  subject { JSON.parse(response.body) }

  describe "GET item/1" do
    before { generate_and_set_token(user) }

    it "returns the item" do
      get :show, params: { id: item.id }
      expect(response.status).to eq(200)
      expect(parsed_body['item']['id']).to eq(item.id)
    end

    describe "known bugs" do
      describe "polymorphic serialization" do
        let(:package) { create :package, id: item.id }
        let(:item) { create(:item, offer: offer) }

        before do
          create(:image, imageable: item)
          create(:image, imageable: package)
        end

        it { expect(package.id).to eq(item.id) }
        it { expect(package.reload.images.count).to eq(1) }
        it { expect(item.reload.images.count).to eq(1) }

        it "returns only the images of the item" do
          get :show, params: { id: item.id }
          expect(response.status).to eq(200)
          expect(parsed_body['item']['image_ids']).to eq([item.images.first.id])
        end
      end
    end
  end

  describe "DELETE item/1" do
    before { generate_and_set_token(user) }
    let(:item) { create :item, offer: offer, state: "draft" }

    it 'should not delete the last item if offer not draft' do
      offer = create :offer, created_by: user, state: 'reviewed'
      item = create :item, offer: offer, state: "accepted"
      delete :destroy, params: { id: item.id }
      expect(response.status).to eq(422)
      body = JSON.parse(response.body)
      expect(body['errors']).to eq('Cannot delete the last item of a submitted offer')
    end

    it "should delete draft item" do
      delete :destroy, params: { id: item.id }
      expect(response.status).to eq(200)
      expect(Item.only_deleted.count).to be_zero
      body = JSON.parse(response.body)
      expect(body).to be_empty
    end

    it 'should revert to under_review offer state if deleted item is last accepted item' do
      offer = create :offer, created_by: user, state: 'reviewed'
      item = create :item, offer: offer, state: 'accepted'
      create :item, offer: offer, state: 'rejected'

      delete :destroy, params: { id: item.id }
      expect(response.status).to eq(200)
      offer.reload
      expect(offer.state).to eq('under_review')
    end
  end

  describe "POST item/1" do
    before { generate_and_set_token(user) }
    it "returns 201", :show_in_doc do
      post :create, params: { item: item_params }
      expect(response.status).to eq(201)
    end
  end

  describe "PUT item/1" do
    before { generate_and_set_token(user) }
    it "owner can update", :show_in_doc do
      put :update, params: { id: item.id, item: { donor_description: 'Test item' } }
      expect(response.status).to eq(200)
      expect(item.reload.donor_description).to eq('Test item')
    end

    let!(:gogovan_order) { create :gogovan_order, :active }
    let!(:delivery) { create :delivery, gogovan_order: gogovan_order }
    let(:offer) { create(:offer, created_by: user) }
    let(:item) { create(:item, offer: offer) }
    it 'should not allow last item to be rejected if there\'s a confirmed gogovan booking' do
      offer.update(delivery: delivery, state: 'scheduled')
      put :update, params: { id: item.id, item: item_params.merge({state_event:'reject'}) }
      expect(response.status).to eq(422)
      body = JSON.parse(response.body)
      expect(body['errors'][0]['requires_gogovan_cancellation']).not_to be_nil
    end

    describe "update donor_condition" do
      before { generate_and_set_token(create(:user, :with_reviewer_role, :with_can_manage_items_permission)) }

      # TODO refactor this test, is not actually checking job is created
      it "should add stockit-update-item request job" do
        item = create :item, state: "accepted"
        package = create :package, :received, item: item
        conditions = create_list :donor_condition, 3
        conditions.delete(item.donor_condition)
        extra_params = { donor_condition_id: conditions.last.id }
        # expect(StockitUpdateJob).to receive(:perform_later).with(package.id)
        put :update, params: { id: item.id, item: item.attributes.except("id").merge(extra_params) }
        expect(response.status).to eq(200)
      end
    end
  end
end
