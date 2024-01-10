require "rails_helper"

RSpec.describe Api::V1::StocktakesController, type: :controller do
  let(:stock_manager) { create(:user, :with_can_manage_stocktakes_permission) }
  let(:stock_fulfilment_user) { create(:user, :with_can_manage_stocktake_revisions_permission) }
  let(:other_user) { create(:user) }
  let(:location) { create(:location) }
  let(:stocktake) { create(:stocktake, location: location) }
  let(:parsed_body) { JSON.parse(response.body) }

  let(:package_1) { create(:package, received_quantity: 10) }
  let(:package_2) { create(:package, received_quantity: 10) }
  let(:package_3) { create(:package, received_quantity: 10) }

  before do
    touch(stocktake)
    initialize_inventory(package_1, package_2, package_3, location: location)
    create(:stocktake_revision, package: package_1, stocktake: stocktake, quantity: 12)  # we counted more
    create(:stocktake_revision, package: package_2, stocktake: stocktake, quantity: 8)   # we counted less
    create(:stocktake_revision, package: package_3, stocktake: stocktake, quantity: 10)  # we counted the same amount
    stocktake.reload
  end

  describe "GET /stocktakes" do
    context "as a user without the 'can_manage_stocktake' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        get :index
        expect(response.status).to eq(403)
      end
    end

    context "as a user with 'can_manage_stocktake' permission" do
      before { generate_and_set_token(stock_manager) }

      it "returns 200" do
        get :index
        expect(response.status).to eq(200)
      end

      it "returns all stocktakes" do
        get :index
        expect(parsed_body["stocktakes"].length).to eq(1)
        expect(parsed_body["stocktakes"].first["id"]).to eq(stocktake.id)
      end

      it "includes stocktake revisions" do
        get :index
        expect(parsed_body["stocktake_revisions"].length).to eq(3)
      end

      context "with ?include_revisions set to false" do
        it "does not include stocktake revisions" do
          get :index, params: { include_revisions: false }
          expect(parsed_body["stocktake_revisions"]).to be_nil
        end
      end
    end

    context "as a user with 'can_manage_stocktake_revisions' permission" do
      before { generate_and_set_token(stock_fulfilment_user) }

      it "returns 200" do
        get :index
        expect(response.status).to eq(200)
      end

      it "returns all stocktakes" do
        get :index
        expect(parsed_body["stocktakes"].length).to eq(1)
        expect(parsed_body["stocktakes"].first["id"]).to eq(stocktake.id)
      end

      it "includes stocktake revisions" do
        get :index
        expect(parsed_body["stocktake_revisions"].length).to eq(3)
      end

      context "with ?include_revisions set to false" do
        it "does not include stocktake revisions" do
          get :index, params: { include_revisions: false }
          expect(parsed_body["stocktake_revisions"]).to be_nil
        end
      end
    end
  end

  describe "GET /stocktakes/:id" do
    context "as a user without the 'can_manage_stocktake' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        get :show, params: { id: stocktake.id }
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(stock_manager) }

      it "returns 200" do
        get :show, params: { id: stocktake.id }
        expect(response.status).to eq(200)
      end

      it "returns the requested stocktake" do
        get :show, params: { id: stocktake.id }
        expect(parsed_body["stocktake"]["id"]).to eq(stocktake.id)
      end

      it "includes stocktake revisions" do
        get :show, params: { id: stocktake.id }
        expect(parsed_body["stocktake_revisions"].length).to eq(3)
      end

      context "with ?include_revisions set to false" do
        it "does not include stocktake revisions" do
          get :show, params: { id: stocktake.id, include_revisions: false }
          expect(parsed_body["stocktake_revisions"]).to be_nil
        end
      end
    end
  end

  describe "POST /stocktakes" do
    let(:other_location) { create(:location) }
    let(:other_packages) { (1..3).map { create(:package, received_quantity: 10) } }

    let(:payload) {
      { location_id: location.id, name: 'lorem stocktake', state: 'open', comment: 'Comment' }
    }

    before { initialize_inventory(other_packages, location: other_location) }

    context "as a user without the 'can_manage_stocktake' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        post :create, params: { stocktake: payload }
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(stock_manager) }

      it "returns 201" do
        post :create, params: { stocktake: payload }
        expect(response.status).to eq(201)
      end

      it "creates a new stocktake" do
        expect {
          post :create, params: { stocktake: payload }
        }.to change(Stocktake, :count).by(1)

        expect(parsed_body["stocktake"]["location_id"]).to eq(payload[:location_id])
        expect(parsed_body["stocktake"]["name"]).to eq(payload[:name])
        expect(parsed_body["stocktake"]["comment"]).to eq(payload[:comment])
        expect(parsed_body["stocktake"]["state"]).to eq("open")
      end

      it "always creates a new stocktake with an 'open' state" do
        payload[:state] = "closed" # should be ignored
        post :create, params: { stocktake: payload }
        expect(parsed_body["stocktake"]["state"]).to eq("open")
      end

      it "prepopulates the stocktake with revisions marked as dirty" do
        expect {
          post :create, params: { stocktake: payload }
        }.to change(Stocktake, :count).by(1)

        record = Stocktake.last
        expect(record.revisions.length).to eq(other_packages.length)
        expect(record.revisions.map(&:dirty).uniq).to eq([true])
        expect(record.revisions.map(&:quantity).uniq).to eq([0])
      end

      it "fails to create a stocktake with an existing name" do
        create(:stocktake, name: payload[:name]);

        expect {
          post :create, params: { stocktake: payload }
        }.to change(Stocktake, :count).by(0)

        expect(response.status).to eq(409)
        expect(parsed_body['error']).to eq('A record already exists')
      end
    end
  end

  describe "DELETE /stocktakes:id" do
    context "as a user without the 'can_manage_stocktake' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        delete :destroy, params: { id: stocktake.id }
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(stock_manager) }

      it "returns 200" do
        delete :destroy, params: { id: stocktake.id }
        expect(response.status).to eq(200)
      end

      it "deletes the stocktake" do
        expect {
          delete :destroy, params: { id: stocktake.id }
        }.to change(Stocktake, :count).by(-1)
      end

      it "deletes the stocktake revisions" do
        expect {
          delete :destroy, params: { id: stocktake.id }
        }.to change(StocktakeRevision, :count).by(-3)
      end
    end
  end

  describe 'PUT /stocktake/:id/commit' do
    context "as a  user without the 'can_manage_stocktake' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        put :commit, params: { id: stocktake.id }
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(stock_manager) }

      it "returns 200" do
        put :commit, params: { id: stocktake.id }
        expect(response.status).to eq(200)
      end

      it "queues up a Stocktake job" do
        expect(StocktakeJob).to receive(:perform_later).with(stocktake.id).once
        put :commit, params: { id: stocktake.id }
        expect(response.status).to eq(200)
      end

      it "marks the stocktake as awaiting process" do
        expect {
          put :commit, params: { id: stocktake.id }
        }.to change {
          stocktake.reload.state
        }.from('open').to('awaiting_process')

        expect(parsed_body['stocktake']['state']).to eq('awaiting_process')
      end

      it "rejects a closed stocktake" do
        stocktake.update(state: 'closed')
        expect(StocktakeJob).not_to receive(:perform_later)
        put :commit, params: { id: stocktake.id }
        expect(response.status).to eq(422)
      end

      it "rejects a cancelled stocktake" do
        stocktake.update(state: 'cancelled')
        expect(StocktakeJob).not_to receive(:perform_later)
        put :commit, params: { id: stocktake.id }
        expect(response.status).to eq(422)
      end

      it "allows a stocktake awaiting process without queuing up a new job" do
        stocktake.update(state: 'awaiting_process')
        expect(StocktakeJob).not_to receive(:perform_later)
        put :commit, params: { id: stocktake.id }
        expect(response.status).to eq(200)
      end

      it "allows a stocktake in process without queuing up a new job" do
        stocktake.update(state: 'processing')
        expect(StocktakeJob).not_to receive(:perform_later)
        put :commit, params: { id: stocktake.id }
        expect(response.status).to eq(200)
      end

      it "rejects a stocktake with dirty revisions" do
        stocktake.revisions.first.update(dirty: true)
        expect(StocktakeJob).not_to receive(:perform_later)
        put :commit, params: { id: stocktake.id }
        expect(response.status).to eq(422)
      end
    end
  end

  describe 'PUT /stocktake/:id/cancel' do
    context "as a user without the 'can_manage_stocktake' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        put :cancel, params: { id: stocktake.id }
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(stock_manager) }

      it "returns 200" do
        put :cancel, params: { id: stocktake.id }
        expect(response.status).to eq(200)
      end

      it "cancels the stocktake" do
        expect {
          put :cancel, params: { id: stocktake.id }
        }.to change {
          stocktake.reload.state
        }.from('open').to('cancelled')

        expect(
          stocktake.revisions.map(&:state).uniq
        ).to eq(['cancelled'])

        expect(parsed_body['stocktake']['state']).to eq('cancelled')
      end
    end
  end
end
