require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do

  let(:user) { create(:user_with_token, :reviewer) }
  let(:serialized_user) { Api::V1::UserSerializer.new(user) }
  let(:serialized_user_json) { JSON.parse( serialized_user.to_json ) }

  let(:users) { create_list(:user, 2) }

  describe "GET user" do
    before { generate_and_set_token(user) }

    it "returns 200" do
      get :show, id: user.id
      expect(response.status).to eq(200)
    end

    it "return serialized user", :show_in_doc do
      get :show, id: user.id
      body = JSON.parse(response.body)
      expect( body ).to eq(serialized_user_json)
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
    let(:permission) { create(:permission, name: "Supervisor") }

    context "Reviewer" do
      before { generate_and_set_token(user) }
      it "update user last_connected time", :show_in_doc do
        put :update, id: user.id, user: { last_connected: 5.days.ago.to_s }
        expect(response.status).to eq(200)
        expect(user.reload.last_connected.to_date).to eq(5.days.ago.to_date)
      end

      it "update user last_disconnected time", :show_in_doc do
        put :update, id: user.id, user: { last_disconnected: 3.days.ago.to_s }
        expect(response.status).to eq(200)
        expect(user.reload.last_disconnected.to_date).to eq(3.days.ago.to_date)
      end

      it "update user permission", :show_in_doc do
        put :update, id: reviewer.id, user: { permission_id: permission.id }
        expect(response.status).to eq(200)
        expect(reviewer.reload.permission).not_to eq(permission)
      end
    end

    context "Supervisor" do
      let(:supervisor) { create(:user_with_token, :supervisor) }
      before { generate_and_set_token(supervisor) }

      it "update user permission", :show_in_doc do
        put :update, id: reviewer.id, user: { permission_id: permission.id }
        expect(response.status).to eq(200)
        expect(reviewer.reload.permission).to eq(permission)
      end
    end
  end

end
