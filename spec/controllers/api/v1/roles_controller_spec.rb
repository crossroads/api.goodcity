require 'rails_helper'

RSpec.describe Api::V1::RolesController, type: :controller do
  let(:user) { create(:user_with_token) }
  let(:role) { create(:role, :with_dynamic_permission, permissions: ['can_create_package']) }
  let(:serialized_role) { Api::V1::RoleSerializer.new(role) }
  let(:serialized_role_json) { JSON.parse( serialized_role.to_json ) }

  let(:roles) { create_list(:role, 2) }

  describe "GET role/1" do

   before { generate_and_set_token(user) }

    it "returns 200" do
      get :show, id: role.id
      expect(response.status).to eq(200)
    end

    it "return serialized role", :show_in_doc do
      get :show, id: role.id
      body = JSON.parse(response.body)
      expect( body ).to eq(serialized_role_json)
    end
  end

  describe "GET roles" do
    before { generate_and_set_token(user) }
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    # it "return serialized offers", :show_in_doc do
    #   2.times{ create :role }
    #   get :index
    #   body = JSON.parse(response.body)
    #   expect( body['roles'].length ).to eq(Role.count)
    # end
  end
end
