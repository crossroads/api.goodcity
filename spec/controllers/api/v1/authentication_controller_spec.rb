require 'rails_helper'
RSpec.describe Api::V1::AuthenticationController, type: :controller do

  describe '.login' do
    let!(:user) {create(:user_with_token)}
    let!(:pin)  {user.most_recent_token.otp_code}
    let!(:token) {user.most_recent_token[:otp_secret_key]}
    let!(:jwt_token) {
      controller.send(:generate_enc_session_token,user.mobile,token)
    }
    let!(:mobile_no){ "+85211111111" }
    let(:correct_mobile_params) {
      attributes_for(:user_with_correct_number).merge(
        {address_attributes: attributes_for(:profile_address).slice(:district_id, :address_type)})
    }
    let(:wrong_mobile_params) {
      attributes_for(:user_with_wrong_number).merge(
        {address_attributes: attributes_for(:profile_address).slice(:district_id, :address_type)})
    }
    describe  "GET - Is the given mobile number unique?" do
      it 'return true if mobile does not exist', :show_in_doc do
        get :is_unique_mobile_number, format: 'json', mobile: mobile_no
        body = JSON.parse(response.body)
        expect(body["is_unique_mobile"]).to be false
      end
    end

    context "POST auth/signup" do
      it 'returns 200', :show_in_doc do
        User.where("mobile =?", correct_mobile_params[:mobile]).first.try(:delete)
        VCR.use_cassette "sign up user" do
          post :signup, format: 'json', user_auth: correct_mobile_params
        end
        expect((JSON.parse(response.body)["token"]).length).to be >= 16
        expect(JSON.parse(response.body)["message"]).to eq("Success")
      end

      it 'return 403', :show_in_doc do
        VCR.use_cassette "unsuccessful sign up user" do
          post :signup, format: 'json', user_auth: wrong_mobile_params
        end
        expect(request.env["warden.options"][:message][:text]).to eq("The number #{wrong_mobile_params[:mobile]} is unverified")
        expect(request.env["warden.options"][:status]).to eq(:forbidden)
      end
    end

    context "POST auth/verify" do
      it 'should allow access to user after signed-in', :show_in_doc do
        allow(controller.send(:warden)).to receive(:authenticate!).with(:pin).and_return(user, true)
        allow(controller.send(:warden)).to receive(:authenticated?).and_return(true)
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{token}"

        post :verify, format: 'json', token: token, pin: pin
        expect(response.message).to eq("OK")
        expect(response.status).to eq(200)
        expect(controller.send(:generate_enc_session_token , user.mobile, token)).not_to be nil
      end

      it 'decode encoded token should have valid data', :show_in_doc do
        login_as(user)
        cur_time = Time.now
        decoded_token = controller.send(:decode_session_token , jwt_token)
        expect(decoded_token["mobile"]).to eq(user.mobile)
        expect(decoded_token["otp_secret_key"]).to eq(user.friendly_token)
        expect(decoded_token["iss"]).to eq(Rails.application.secrets.jwt['issuer'])
        expect(decoded_token["exp"]).to be > cur_time.to_i
        expect(decoded_token["iat"]).to be <= cur_time.to_i
      end
    end

    context "GET auth/resend" do
      it 'should resend pin for a valid secret token', :show_in_doc do
        login_as(user)
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
        VCR.use_cassette "user OTP secret token" do
          get :resend
        end
        expect(JSON.parse(response.body)["token"]).to include(token)
        expect(JSON.parse(response.body)["message"]).to eq(I18n.t('auth.pin_sent'))
      end

      it 'should not resend pin for a token is empty', :show_in_doc do
        login_as(user)
        request.env['HTTP_AUTHORIZATION'] = "  Bearer    "
        get :resend
        expect(request.env["warden.options"][:message][:text]).to eq("Please provide a mobile number.")
        expect(request.env["warden.options"][:message][:token]).to eq("")
        expect(response.status_message.downcase).to eq("unauthorized")
      end

      it 'should not resend pin as secret token is not in autherized ', :show_in_doc do
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
          get :resend, format: 'json', mobile: '+85211111111'
        end
        expect(JSON.parse(response.body)["mobile_exist"]).to be true
        expect(JSON.parse(response.body)["token"]).not_to eql("")
      end

      it 'should not send pin to an invalid mobile' do
        login_as user
        VCR.use_cassette "valid user with verified mobile" do
          get :resend, format: 'json', mobile: '+85211111112'
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
