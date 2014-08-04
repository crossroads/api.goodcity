require 'rails_helper'
RSpec.describe Api::V1::AuthenticationController, type: :controller do
  describe '.login' do
    let!(:user) {create(:user_with_specifics)}
    let!(:pin) {user.auth_tokens.recent_auth_token[:otp_code]}
    let!(:token) {user.auth_tokens.recent_auth_token[:otp_secret_key]}
    let!(:jwt_token) {
      controller.send(:generate_enc_session_token,user.mobile,token)
    }
    let!(:mobile_no){ "+919930001948" }

    it 'verifies mobile exists' do
      get :is_unique_mobile_number, format: 'json', mobile: mobile_no
      expect(JSON.parse(response.body)["is_unique_mobile"]).to be false
    end

    context "sign up" do
      it 'new user successfully' do
        User.where("mobile =?", mobile_no).first.try(:delete)
        VCR.use_cassette "sign up user" do
          post :signup, format: 'json', user_auth: {mobile: mobile_no, first_name: "Jake",
            last_name: "Deamon"}
        end
        expect((JSON.parse(response.body)["token"]).length).to be >= 16
        expect(JSON.parse(response.body)["message"]).to eq("Success")
      end

      it 'new user unsuccessful' do
        wrong_mobile_no = "+9199930001949"
        VCR.use_cassette "unsuccessful sign up user" do
          post :signup, format: 'json', user_auth: {mobile: wrong_mobile_no, first_name: "Jake",
            last_name: "Deamon"}
        end
        expect(request.env["warden.options"][:message][:text]).to eq("The number #{wrong_mobile_no} is unverified")
        expect(request.env["warden.options"][:status]).to eq(:forbidden)
      end
    end
    context "verify user" do
      it 'should allow access to user after signed-in' do
        allow(controller.warden).to receive(:authenticate!).with(:pin).and_return(user, true)
        allow(controller.warden).to receive(:authenticated?).and_return(true)
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{token}"

        post :verify, format: 'json', token: token, pin: pin
        expect(response.message).to eq("OK")
        expect(response.status).to eq(200)
        expect(controller.send(:generate_enc_session_token , user.mobile, token)).not_to be nil
      end

      it 'decode encoded token should have valid data' do
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
        expect(JSON.parse(response.body)["message"]).to eq(I18n.t('auth.pin_sent'))
      end

      it 'should not resend pin for a token is empty' do
        login_as(user)
        request.env['HTTP_AUTHORIZATION'] = "  Bearer    "
        get :resend
        expect(request.env["warden.options"][:message][:text]).to eq("Mobile number does not exist.")
        expect(request.env["warden.options"][:message][:token]).to eq("")
        expect(response.status_message.downcase).to eq("unauthorized")
      end

      it 'should not resend pin as secret token is not in autherized ' do
        login_as(user)
        request.env['HTTP_AUTHORIZATION'] = "Bearer  xr2ysdkj12kkjs2"
        VCR.use_cassette "user OTP secret token" do
          get :resend
        end
        expect(request.env["warden.options"][:message][:token]).to eq("")
        expect(request.env["warden.options"][:message][:text]).to eq(I18n.t("auth.mobile_required"))
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
        expect(request.env["warden.options"][:message][:mobile_exist]).to be false
        expect(request.env["warden.options"][:message][:token]).to eql("")
        expect(response.status_message.downcase).to eq("unauthorized")
      end
    end

    it 'verified OTP and generate the secret token' do
      user
    end
  end
end
