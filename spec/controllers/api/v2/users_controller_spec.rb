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

  describe '/api/v2/:id/update_phone_number' do
    let(:user) { create(:user, :with_token) }
    let(:mobile) { '+85290369036' }
    let(:jwt) { Token.new.generate_otp_token({
      pin_method:     :mobile,
      otp_auth_key:   AuthenticationService.otp_auth_key_for(user),
      mobile: mobile
    }) }
    let(:otp_auth) { user.most_recent_token}
    let(:otp_auth_key) { otp_auth.otp_auth_key }
    let(:otp) { otp_auth.otp_code }

    before do
      generate_and_set_token(user)
    end

    context 'if pin is valid' do
      before { allow(AuthenticationService).to receive(:authenticate!).with(anything, strategy: :pin_jwt).and_return(user) }

      it 'updates a users mobile number' do
        put :update_phone_number, params: { id: user.id, token: jwt, otp: otp }

        expect(response).to have_http_status(:success)
        expect(user.reload.mobile).to eq(mobile)
      end
    end

    context 'if pin is invalid' do
      before { allow(AuthenticationService).to receive(:authenticate).with(anything, strategy: :pin_jwt).and_return(nil) }

      it 'throws invalid pin error' do
        put :update_phone_number, params: { id: user.id, token: jwt, otp: otp }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not updates the mobile number' do
        expect {
          put :update_phone_number, params: { id: user.id, token: jwt, otp: otp }
        }.to_not change { user.reload }
      end
    end

    context 'if mobile number is duplicate' do
      let(:another_user) { create(:user, :with_token) }
      let(:mobile) { another_user.mobile }

      before { allow(AuthenticationService).to receive(:authenticate!).with(anything, strategy: :pin_jwt).and_return(user) }

      it 'throws duplicate mobile number error' do
        put :update_phone_number, params: { id: user.id, token: jwt, otp: otp }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not update the mobile number' do
        expect {
          put :update_phone_number, params: { id: user.id, token: jwt, otp: otp }
        }.to_not change { user.reload }
      end
    end
  end
end
