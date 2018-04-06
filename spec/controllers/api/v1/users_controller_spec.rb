require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do

  let(:user) { create(:user_with_token, :with_can_read_or_modify_user_permission, role_name: 'Reviewer') }
  let(:serialized_user) { Api::V1::UserSerializer.new(user) }
  let(:serialized_user_json) { JSON.parse( serialized_user.to_json ) }

  let(:users) { create_list(:user, 2) }

  describe "GET user" do
    before { generate_and_set_token(user) }

    it "returns 200" do
      get :show, id: user.id
      expect(response.status).to eq(200)
    end
  end

  describe "GET users" do
    before { generate_and_set_token(user) }
    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized users" do
      get :index
      body = JSON.parse(response.body)
      expect( body['users'].length ).to eq(User.count)
    end
  end

  describe "PUT user/1" do
    let(:reviewer) { create(:user_with_token, :reviewer) }
    let(:role) { create(:role, name: "Supervisor") }

    context "Reviewer" do
      before { generate_and_set_token(user) }
      it "update user last_connected time", :show_in_doc do
        put :update, id: user.id, user: { last_connected: 5.days.ago.to_s, user_role_ids: [role.id] }
        expect(response.status).to eq(200)
        expect(user.reload.last_connected.to_date).to eq(5.days.ago.to_date)
      end

      it "update user last_disconnected time", :show_in_doc do
        put :update, id: user.id, user: { last_disconnected: 3.days.ago.to_s, user_role_ids: [role.id] }
        expect(response.status).to eq(200)
        expect(user.reload.last_disconnected.to_date).to eq(3.days.ago.to_date)
      end

      it "adds user role", :show_in_doc do
        expect{
          put :update, id: reviewer.id, user: { user_role_ids: [role.id] }
        }.to change(UserRole, :count).by(1)
        expect(response.status).to eq(200)
        expect(reviewer.reload.roles).to include(role)
      end

      it "removes user role if existing role_id is not present in params", :show_in_doc do
        put :update, id: reviewer.id, user: { user_role_ids: [] }
        expect(reviewer.reload.roles.count).to eq(0)
      end

      it "adds new roles and removes old roles as per params", :show_in_doc do
        existing_user_roles = reviewer.roles
        put :update, id: reviewer.id, user: { user_role_ids: [role.id] }
        expect(reviewer.reload.roles).to include(role)
        expect(reviewer.reload.roles).not_to include(existing_user_roles)
      end
    end
  end
end

