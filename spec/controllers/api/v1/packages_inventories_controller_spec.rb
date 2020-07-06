require 'rails_helper'

RSpec.describe Api::V1::PackagesInventoriesController, type: :controller do
  let(:user) { create(:user_with_token, :with_multiple_roles_and_permissions,
    roles_and_permissions: { 'Reviewer' => ['can_manage_packages', 'can_manage_orders']} )}
  let!(:package) { create(:package) }
  let!(:package1) { create(:package) }
  let!(:packages_inventory) { create(:packages_inventory, :gain, package_id: package.id) }
  let!(:packages_inventory2) { create(:packages_inventory, :gain, package_id: package.id) }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET packages_inventories" do

    describe 'returns packages inventories for given package_id' do
      before { generate_and_set_token(user) }

      it "returns 200", :show_in_doc do
        get :index, package_id: package.id
        expect(response.status).to eq(200)
      end

      it "returns all the packages_inventories" do
        get :index, package_id: package.id
        expect(parsed_body['item_actions'].length).to eq(2)
        expect(parsed_body['item_actions'][0]['id']).to eq(packages_inventory.id)
        expect(parsed_body['item_actions'][1]['id']).to eq(packages_inventory2.id)
      end
    end

    describe 'returns packages inventories for given package_id' do
      before { generate_and_set_token(user) }

      it "returns empty packages_inventories" do
        get :index, package_id: package1.id
        expect(parsed_body['item_actions'].length).to eq(0)
      end
    end
  end
end