require 'rails_helper'
RSpec.describe Api::V1::AuthenticationController, type: :controller do
  describe '.login' do
    let!(:user) {create(:user_with_specifics)}
    let!(:pin) {user.auth_tokens.recent_auth_token[:otp_code]}
    let!(:token) {user.auth_tokens.recent_auth_token[:otp_secret_key]}
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
        allow(controller.send(:warden)).to receive(:authenticate!).with(:pin).and_return(user, true)
        allow(controller.send(:warden)).to receive(:authenticated?).and_return(true)
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{token}"

        post :verify, format: 'json', token: token, pin: pin
        expect(response.message).to eq("OK")
        expect(response.status).to eq(200)
      end
    end

    context "resend" do
      it 'should search_by_token if token is valid' do
        allow(controller.send(:token)).to receive(:valid?).and_return(true)
        expect(controller).to receive(:search_by_token)
        get :resend
      end
      it 'should search_by_mobile if token is not valid' do
        allow(controller.send(:token)).to receive(:valid?).and_return(false)
        expect(controller).to receive(:search_by_mobile)
        get :resend
      end
    end

    context "search_by_token" do

      it 'should resend pin if token is valid' do
        allow(controller.send(:token)).to receive(:valid?).and_return(true)
        allow(controller.send(:token)).to receive(:header).and_return(token)
        VCR.use_cassette "user OTP secret token" do
          get :resend
        end
        expect(JSON.parse(response.body)["token"]).to include(token)
        expect(JSON.parse(response.body)["message"]).to eq(I18n.t('auth.pin_sent'))
      end

      it 'should not resend pin if token is not valid' do
        allow(controller.send(:token)).to receive(:valid?).and_return(false)
        expect{ controller.send(:search_by_token) }.to throw_symbol(:warden)
      end

      it 'should not resend pin if secret token does not exist' do
        allow(controller.send(:token)).to receive(:valid?).and_return(true)
        allow(User).to receive(:find_all_by_otp_secret_key).and_return([])
        expect{ controller.send(:search_by_token) }.to throw_symbol(:warden)
      end
    end

    context "search_by_mobile" do
      it 'should resend pin if mobile is valid' do
        VCR.use_cassette "valid user with verified mobile" do
          get :resend, format: 'json', mobile: '+919930001948'
        end
        expect(JSON.parse(response.body)["mobile_exist"]).to be true
        expect(JSON.parse(response.body)["token"]).not_to eql("")
      end

      it 'should not send pin to an invalid mobile' do
        VCR.use_cassette "valid user with verified mobile" do
          get :resend, format: 'json', mobile: '+919930001949'
        end
        expect(request.env["warden.options"][:message][:mobile_exist]).to be false
        expect(request.env["warden.options"][:message][:token]).to eql("")
        expect(request.env["warden.options"][:message][:text]).to eql(I18n.t("auth.mobile_doesnot_exist"))
        expect(response.status_message.downcase).to eq("unauthorized")
      end
    end

  end
end
