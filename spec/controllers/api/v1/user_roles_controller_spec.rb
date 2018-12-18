require 'rails_helper'

RSpec.describe Api::V1::UserRolesController, type: :controller do
	let(:reviewer) { create(:user) }
  let!(:user_role) { create(:user_role, user_id: reviewer.id) }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET user_roles" do
    
    before { generate_and_set_token(reviewer) }

    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized user_role", :show_in_doc do
      get :index, search_by_user_id: reviewer.id
      expect(parsed_body['user_roles'].length).to eq(1)
      expect(parsed_body['user_roles'][0]['role_id']).to eq(user_role.role_id)
      expect(parsed_body['user_roles'][0]['user_id']).to eq(user_role.user_id)
    end
  end

  describe "GET user_role" do
    before do
      generate_and_set_token(reviewer)
      get :show, id: user_role.id
    end
    it "returns 200" do
      expect(response.status).to eq(200)
    end
    it "return serialized user_role", :show_in_doc do
      expect(parsed_body['user_role']['id']).to eq(user_role.id)
      expect(parsed_body['user_role']['role_id']).to eq(user_role.role_id)
      expect(parsed_body['user_role']['user_id']).to eq(user_role.user_id)
    end
  end
end