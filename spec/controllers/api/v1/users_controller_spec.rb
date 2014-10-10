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
end
