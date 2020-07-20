require "rails_helper"

RSpec.describe Api::V1::StocktakesController, type: :controller do
  let(:entitled_user) { create(:user, :with_can_manage_stocktakes_permission) }
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
  end

  describe "GET /stocktakes" do
    context "as a user without the 'can_manage_stocktake' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        get :index
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(entitled_user) }

      it "returns 200" do
        get :index
        expect(response.status).to eq(200)
      end

      it "returns all stocktakes" do
        get :index
        expect(parsed_body["stocktakes"].length).to eq(1)
        expect(parsed_body["stocktakes"].first["id"]).to eq(stocktake.id)
      end
    end
  end

  describe "GET /stocktakes/:id" do
    context "as a user without the 'can_manage_stocktake' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        get :show, id: stocktake.id
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(entitled_user) }

      it "returns 200" do
        get :show, id: stocktake.id
        expect(response.status).to eq(200)
      end

      it "returns the requested stocktake" do
        get :show, id: stocktake.id
        expect(parsed_body["stocktake"]["id"]).to eq(stocktake.id)
      end
    end
  end

  describe "POST /stocktakes" do
    let(:other_location) { create(:location) }
    let(:other_packages) { (1..3).map { create(:package, received_quantity: 10) } }

    let(:payload) {
      { location_id: location.id, name: 'lorem stocktake', state: 'open' }
    }

    before { initialize_inventory(other_packages, location: other_location) }

    context "as a user without the 'can_manage_stocktake' permission" do
      before { generate_and_set_token(other_user) }

      it "returns 403" do
        post :create, stocktake: payload
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(entitled_user) }

      it "returns 201" do
        post :create, stocktake: payload
        expect(response.status).to eq(201)
      end

      it "creates a new stocktake" do
        expect {
          post :create, stocktake: payload
        }.to change(Stocktake, :count).by(1)

        expect(parsed_body["stocktake"]["location_id"]).to eq(payload[:location_id])
        expect(parsed_body["stocktake"]["name"]).to eq(payload[:name])
        expect(parsed_body["stocktake"]["state"]).to eq("open")
      end

      it "always creates a new stocktake with an 'open' state" do
        payload[:state] = "closed" # should be ignored
        post :create, stocktake: payload
        expect(parsed_body["stocktake"]["state"]).to eq("open")
      end

      it "prepopulates the stocktake with revisions marked as dirty" do
        expect {
          post :create, stocktake: payload
        }.to change(Stocktake, :count).by(1)

        record = Stocktake.last
        expect(record.revisions.length).to eq(other_packages.length)
        expect(record.revisions.map(&:dirty).uniq).to eq([true])
        expect(record.revisions.map(&:quantity).uniq).to eq([0])
      end

      it "fails to create a stocktake with an existing name" do
        create(:stocktake, name: payload[:name]);

        expect {
          post :create, stocktake: payload
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
        delete :destroy, id: stocktake.id
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(entitled_user) }

      it "returns 200" do
        delete :destroy, id: stocktake.id
        expect(response.status).to eq(200)
      end

      it "deletes the stocktake" do
        expect {
          delete :destroy, id: stocktake.id
        }.to change(Stocktake, :count).by(-1)
      end

      it "deletes the stocktake revisions" do
        expect {
          delete :destroy, id: stocktake.id
        }.to change(StocktakeRevision, :count).by(-3)
      end
    end
  end

  describe 'PUT /stocktake/:id/commit' do
    context "as a  user without the 'can_manage_stocktake' permission" do
      before { generate_and_set_token(other_user) }
      
      it "returns 403" do
        put :commit, id: stocktake.id
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(entitled_user) }

      it "returns 200" do
        put :commit, id: stocktake.id
        expect(response.status).to eq(200)
      end

      it "creates inventory rows to correct the quantities" do
        expect {
          put :commit, id: stocktake.id
        }.to change(PackagesInventory, :count).by(2)

        change_1, change_2 = PackagesInventory.last(2)
        expect(change_1.package_id).to eq(package_1.id)
        expect(change_1.quantity).to eq(2)
        expect(change_2.package_id).to eq(package_2.id)
        expect(change_2.quantity).to eq(-2)
      end

      it "closes the stocktake" do
        expect {
          put :commit, id: stocktake.id
        }.to change {
          stocktake.reload.state
        }.from('open').to('closed')

        expect(parsed_body['stocktake']['state']).to eq('closed')
      end
    end
  end

  describe 'PUT /stocktake/:id/cancel' do
    context "as a  user without the 'can_manage_stocktake' permission" do
      before { generate_and_set_token(other_user) }
      
      it "returns 403" do
        put :cancel, id: stocktake.id
        expect(response.status).to eq(403)
      end
    end

    context "as a user with correct permissions" do
      before { generate_and_set_token(entitled_user) }

      it "returns 200" do
        put :cancel, id: stocktake.id
        expect(response.status).to eq(200)
      end

      it "cancels the stocktake" do
        expect {
          put :cancel, id: stocktake.id
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
