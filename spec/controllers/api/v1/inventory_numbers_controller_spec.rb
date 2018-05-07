require 'rails_helper'

RSpec.describe Api::V1::InventoryNumbersController, type: :controller do
  let(:user) { create(:user_with_token, :with_can_add_or_remove_inventory_number, role_name: 'Reviewer') }
  let!(:inventory_number) { create(:inventory_number) }

  before { generate_and_set_token(user) }

  describe "POST inventory_number/1" do
    it "creates new record and returns 200", :show_in_doc do
      expect {
        post :create
      }.to change(InventoryNumber, :count).by(1)
      expect(response.status).to eq(200)
    end
  end

  describe "PUT /v1/inventory_numbers Delete InventoryNumber" do
    it 'deletes existing inventory_number and returns blank json' do
      expect {
        post :remove_number, code: inventory_number.code
      }.to change(InventoryNumber, :count).by(-1)
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body).to eq( {} )
    end
  end
end
