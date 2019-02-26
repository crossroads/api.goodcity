require 'rails_helper'

RSpec.describe Api::V1::ProcessChecklistsController, type: :controller do
  let(:manager) { create(:user_with_token, :with_multiple_roles_and_permissions,
    roles_and_permissions: { 'Supervisor' => ['can_manage_orders']} )}
  let(:user) { create(:user_with_token) }
  let!(:process_checklist) { create(:process_checklist) }
  let!(:process_checklist2) { create(:process_checklist) }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET process_checklists" do

    describe 'as a user with can_manage_orders ability' do
      before { generate_and_set_token(manager) }

      it "returns 200", :show_in_doc do
        get :index
        expect(response.status).to eq(200)
      end

      it "returns all the items" do
        get :index
        expect(parsed_body['process_checklists'].length).to eq(2)
        expect(parsed_body['process_checklists'][0]['id']).to eq(process_checklist.id)
        expect(parsed_body['process_checklists'][1]['id']).to eq(process_checklist2.id)
      end
    end

    describe 'as an anonymous user' do
      it "returns 401", :show_in_doc do
        get :index
        expect(response.status).to eq(401)
      end
    end

    describe 'as a user without the ability' do
      before { generate_and_set_token(user) }

      it "returns 403", :show_in_doc do
        get :index
        expect(response.status).to eq(403)
      end
    end
  end
end