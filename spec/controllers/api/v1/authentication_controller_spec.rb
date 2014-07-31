require 'rails_helper'
RSpec.describe Api::V1::AuthenticationController, type: :controller do
  describe '.login' do
    let!(:user) {create(:user_with_specifics)}
    let!(:pin) {user.auth_tokens.recent_auth_token[:otp_code]}
    let!(:token) {user.auth_tokens.recent_auth_token[:otp_secret_key]}
    let!(:jwt_token) {
      controller.send(:generate_enc_session_token,user.mobile,token)
    }

    it 'verifies mobile exists' do
      get :is_unique_mobile_number, format: 'json', mobile: '+919930001948'
      expect(JSON.parse(response.body)["is_unique_mobile"]).to be false
    end

    context "verify user" do
      it 'should allow access to user if signed-in' do
        login_as(user)
        post :verify, format: 'json', token: token, pin: pin
        expect(response.message).to eq("OK")
        expect(response.status).to eq(200)
      end

      it 'generated encoded token should have valid data' do
        login_as(user)
        cur_time = Time.now
        decoded_token = controller.send(:decode_session_token , jwt_token)
        expect(decoded_token["mobile"]).to eq(user.mobile)
        expect(decoded_token["otp_secret_key"]).to eq(user.friendly_token)
        expect(decoded_token["iss"]).to eq(ISSUER)
        expect(decoded_token["exp"]).to be > cur_time.to_i
        expect(decoded_token["iat"]).to be <= cur_time.to_i
      end
    end

    context "should retrieve details using OTP secret token" do
      it 'should resend pin for a valid secret token' do
        login_as(user)
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
        VCR.use_cassette "user OTP secret token" do
          get :resend
        end
        expect(JSON.parse(response.body)["token"]).to include(token)
        expect(JSON.parse(response.body)["msg"]).to eq(I18n.t('auth.pin_sent'))
      end

      it 'should not resend pin for a invalid token' do
        login_as(user)
        request.env['HTTP_AUTHORIZATION'] = "  Bearer    "
        get :resend

        expect(JSON.parse(response.body)["mobile_exist"]).to be false
        expect(JSON.parse(response.body)["token"]).to eq("")
        expect(response.message.downcase).to eq("unauthorized")
      end
  end

  context "should retrieve details using mobile" do

    it 'should resend pin for a valid mobile' do
      login_as user
      VCR.use_cassette "valid user with verified mobile" do
        get :resend, format: 'json', mobile: '+919930001948'
      end
      expect(JSON.parse(response.body)["mobile_exist"]).to be true
      expect(JSON.parse(response.body)["token"]).not_to eql("")
    end

    it 'should not send pin to an invalid mobile' do
      login_as user
      VCR.use_cassette "valid user with verified mobile" do
        get :resend, format: 'json', mobile: '+919930001949'
      end
      expect(JSON.parse(response.body)["mobile_exist"]).to be false
      expect(JSON.parse(response.body)["token"]).to  eql("")
    end
  end
    it 'verified OTP and generate the secret token' do
      user
    end
    after(:all) do
      User.destroy_all
    end
   end
end
