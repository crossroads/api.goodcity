require "rails_helper"

RSpec.describe Api::V1::StocktakeRevisionsController, type: :controller do
  let(:entitled_user) { create(:user, :with_can_manage_stocktake_revisions_permission) }
  let(:other_user) { create(:user) }
  let(:location) { create(:location) }
  let(:stocktake) { create(:stocktake, location: location) }
  let(:parsed_body) { JSON.parse(response.body) }

  let(:package_1) { create(:package, received_quantity: 10) }
  let(:package_2) { create(:package, received_quantity: 10) }
  let(:package_3) { create(:package, received_quantity: 10) }
  let(:package_4) { create(:package, received_quantity: 10) }

  before do
    touch(stocktake)
    initialize_inventory(package_1, package_2, package_3, package_4, location: location)
    create(:stocktake_revision, package: package_1, stocktake: stocktake, quantity: 12)  # we counted more
    create(:stocktake_revision, package: package_2, stocktake: stocktake, quantity: 8)   # we counted less
    create(:stocktake_revision, package: package_3, stocktake: stocktake, quantity: 10)  # we counted the same amount
  end

  describe "POST /stocktake_revisions" do
    let(:payload) {
      { quantity: 3, package_id: package_4.id, state: 'pending', stocktake_id: stocktake.id }
    }

    context "as a user without the 'can_manage_stocktake_revisions' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        post :create, params: { stocktake_revision: payload }
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(entitled_user) }

      it "returns 201" do
        post :create, params: { stocktake_revision: payload }
        expect(response.status).to eq(201)
      end

      it "creates a new revision" do
        expect {
          post :create, params: { stocktake_revision: payload }
        }.to change(StocktakeRevision, :count).by(1)

        expect(parsed_body["stocktake_revision"]["quantity"]).to eq(payload[:quantity])
        expect(parsed_body["stocktake_revision"]["package_id"]).to eq(payload[:package_id])
        expect(parsed_body["stocktake_revision"]["state"]).to eq("pending")
        expect(parsed_body["stocktake_revision"]["stocktake_id"]).to eq(stocktake.id)
      end

      it "defaults to a 'pending' state if missing" do
        expect {
          post :create, params: { stocktake_revision: payload.except(:state) }
        }.to change(StocktakeRevision, :count).by(1)

        expect(parsed_body["stocktake_revision"]["quantity"]).to eq(payload[:quantity])
        expect(parsed_body["stocktake_revision"]["package_id"]).to eq(payload[:package_id])
        expect(parsed_body["stocktake_revision"]["state"]).to eq("pending")
        expect(parsed_body["stocktake_revision"]["stocktake_id"]).to eq(stocktake.id)
      end

      it "fails to create a revision if it already exists for that package" do
        expect {
          post :create, params:{ stocktake_revision: payload.merge({ package_id: package_3.id }) }
        }.to change(StocktakeRevision, :count).by(0)

        expect(response.status).to eq(409)
        expect(parsed_body['error']).to eq('A record already exists')
      end
    end
  end

  describe "DELETE /stocktake_revisions/:id" do
    let(:stocktake_revision) { stocktake.reload.revisions.first }

    context "as a user without the 'can_manage_stocktake_revisions' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        delete :destroy, params: { id: stocktake_revision.id }
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(entitled_user) }

      it "returns 200" do
        delete :destroy, params: { id: stocktake_revision.id }
        expect(response.status).to eq(200)
      end

      it "deletes the revision" do
        expect {
          delete :destroy, params: { id: stocktake_revision.id }
        }.to change(StocktakeRevision, :count).by(-1)
      end

      it "does not delete the stocktake" do
        expect {
          delete :destroy, params: { id: stocktake_revision.id }
        }.not_to change(Stocktake, :count)
      end
    end
  end

  describe 'PUT /stocktake/:id' do
    let(:stocktake_revision) { stocktake.reload.revisions.first }
    let!(:initial_quantity) { stocktake_revision.quantity }

    context "as a  user without the 'can_manage_stocktake_revisions' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        put :update, params: { id: stocktake_revision.id }
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(entitled_user) }

      it "returns 200" do
        put :update, params: { id: stocktake_revision.id, stocktake_revision: { quantity: 100 } }
        expect(response.status).to eq(200)
      end

      it "Updates the record" do
        expect {
          put :update, params: { id: stocktake_revision.id, stocktake_revision: { quantity: 100 } }
        }.to change {
          stocktake_revision.reload.quantity
        }.from(initial_quantity).to(100)
      end
    end
  end
end
