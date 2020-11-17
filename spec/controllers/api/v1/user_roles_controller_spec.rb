require 'rails_helper'

RSpec.describe Api::V1::UserRolesController, type: :controller do
  let(:reviewer) { create(:user, :with_token,:with_can_manage_user_roles_permission,
                   role_name: "Reviewer") }
  let(:user_role) { reviewer.user_roles.first }
  let(:parsed_body) { JSON.parse(response.body) }
  let!(:reviewer_user) { create(:user, :with_can_manage_offers_permission, role_name: "Reviewer") }
  let!(:admin_user) { create(:user, :with_can_manage_orders_permission, role_name: "System administrator") }

  # ROLES
  let!(:reviewer_role) { create(:role, name: "Reviewer", level: 5) }
  let!(:order_fulfilment_role) { create(:role, name: "Order fulfilment", level: 5) }
  let!(:system_admin_role) { create(:role, name: "System administrator", level: 15) }

  describe "GET user_roles" do
    before { generate_and_set_token(reviewer) }

    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized user_role", :show_in_doc do
      reviewer.roles = [reviewer_role]
      get :index, params: { search_by_user_id: reviewer.id }

      expect(parsed_body['user_roles'].length).to eq(1)
      expect(parsed_body['user_roles'][0]['role_id']).to eq(reviewer_role.id)
      expect(parsed_body['user_roles'][0]['user_id']).to eq(reviewer.id)
    end
  end

  describe "GET user_role" do
    before do
      generate_and_set_token(reviewer)
      get :show, params: { id: user_role.id }
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

  describe "POST user_roles" do
    context "Reviewer with permission 'can_manage_user_roles'" do
      before do
        reviewer.roles = [ reviewer_role ]
        generate_and_set_token(reviewer)
      end

      it "Does not assign higher level role to user" do
        post :create, params: { user_role: { user_id: reviewer_user.id, role_id: system_admin_role.id } }

        expect(response.status).to eq(422)
        expect(parsed_body["errors"][0]["message"]["error"]).to eq("You are not authorized to update roles of this user.")
      end

      it "Does assign lower level and same level role to user", :show_in_doc do
        expect {
          post :create, params: { user_role: { user_id: reviewer_user.id, role_id: order_fulfilment_role.id } }
        }.to change(UserRole, :count).by(1)

        expect(response.status).to eq(200)
        expect(parsed_body["user_role"]["role_id"]).to eql(order_fulfilment_role.id)
        expect(parsed_body["user_role"]["user_id"]).to eql(reviewer_user.id)
      end

      it "Does update expiry date for existing role", :show_in_doc do
        expires_at = DateTime.now.in_time_zone.days_since(10)
        expect {
          post :create, params: { user_role: {
            user_id: reviewer_user.id,
            role_id: reviewer_role.id,
            expires_at: expires_at
          } }
        }.to change(UserRole, :count).by(0)

        expect(response.status).to eq(200)
        expect(parsed_body["user_role"]["role_id"]).to eql(reviewer_role.id)
        expect(parsed_body["user_role"]["user_id"]).to eql(reviewer_user.id)
        expect(parsed_body["user_role"]["expires_at"].to_datetime.to_i).to eql(expires_at.to_i)
      end
    end

    context "Reviewer without permission 'can_manage_user_roles'" do
      before do
        generate_and_set_token(reviewer_user)
      end

      it "Does not assign role to other user" do
        post :create, params: { user_role: { user_id: reviewer.id, role_id: system_admin_role.id } }
        expect(response.status).to eq(422)
        expect(parsed_body["errors"][0]["message"]["error"]).to eq("You are not authorized to update roles of this user.")
      end
    end
  end

  describe "Delete user_role" do
    context "Reviewer" do
      before do
        reviewer.roles = [ reviewer_role ]
        generate_and_set_token(reviewer)
      end

      it "Does not delete higher level role of other user" do
        expect {
          delete :destroy, params: { id: admin_user.user_roles.first.id }
        }.to change(admin_user.user_roles, :count).by(0)

        expect(response.status).to eq(422)
        expect(parsed_body["errors"][0]["message"]["error"]).to eq("You are not authorized to update roles of this user.")
        expect(admin_user.reload.user_roles.first.role_id).to eq(system_admin_role.id)
      end

      it "Does delete lower level and same level role to user", :show_in_doc do
        expect {
          delete :destroy, params: { id: reviewer_user.user_roles.first.id }
        }.to change(reviewer_user.user_roles, :count).by(-1)

        expect(response.status).to eq(200)
        expect(reviewer_user.reload.user_roles.count).to eq(0)
      end
    end
  end
end

