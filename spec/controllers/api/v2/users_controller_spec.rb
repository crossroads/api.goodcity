require 'rails_helper'
RSpec.describe Api::V2::UsersController, type: :controller do

  let(:user)          { create(:user, :with_supervisor_role) }
  let(:mobile)        { generate(:mobile) }
  let(:email)         { 'some@email.com' }
  let(:parsed_body)   { JSON.parse(response.body) }
  let(:district)      { create(:district) }

  describe "Fetching the current user /me" do
    context "as a guest" do
      it "returns a 401" do
        get :me
        expect(response.status).to eq(401)
        expect(parsed_body).to eq({
          "error"  => "Invalid token",
          "type"   => "UnauthorizedError",
          "status" => 401
        })
      end
    end

    context "as a logged in user" do
      before { generate_and_set_token(user) }

      it "returns a 200" do
        get :me, format: 'json'
        expect(response.status).to eq(200)
        expect(parsed_body['data']['type']).to eq('user')
        expect(parsed_body['data']['id']).to eq(user.id.to_s)
        expect(parsed_body['data']['attributes']['first_name']).to eq(user.first_name)
      end
    end
  end
end
