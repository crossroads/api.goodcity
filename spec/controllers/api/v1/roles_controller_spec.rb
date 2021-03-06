require 'rails_helper'

RSpec.describe Api::V1::RolesController, type: :controller do
  let(:user) { create(:user, :with_token) }

  let(:role) { create(:reviewer_role, :with_can_manage_packages_permission) }
  let(:serialized_role) { Api::V1::RoleSerializer.new(role).as_json }
  let(:serialized_role_json) { JSON.parse( serialized_role.to_json ) }

  subject { JSON.parse(response.body) }

  describe "GET role/1" do
    before { generate_and_set_token(user) }

    it "returns 200" do
      get :show, params: { id: role.id }
      expect(response.status).to eq(200)
    end

    it "return serialized role", :show_in_doc do
      get :show, params: { id: role.id }
      expect(subject).to eq(serialized_role_json)
    end
  end

  describe "GET roles" do
    before { generate_and_set_token(user) }
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized offers", :show_in_doc do
      create :reviewer_role
      get :index
      expect(subject['roles'].length).to eq(Role.count)
    end
  end
end
