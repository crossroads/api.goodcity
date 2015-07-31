require 'rails_helper'
RSpec.describe Api::V1::AuthenticationController, type: :controller do

  let(:user)   { create(:user_with_token) }
  let(:pin)    { user.most_recent_token[:otp_code] }
  let(:mobile) { generate(:mobile) }
  let(:otp_auth_key) { "/JqONEgEjrZefDV3ZIQsNA==" }
  let(:jwt_token)    { Token.new.generate }
  let(:serialized_user) { Api::V1::UserProfileSerializer.new(user).to_json }

  context "signup" do
    it 'new user successfully', :show_in_doc do
      expect_any_instance_of(User).to receive(:send_verification_pin)
      expect(controller).to receive(:otp_auth_key_for).and_return(otp_auth_key)
      post :signup, format: 'json', user_auth: { mobile: mobile, first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: '1', address_type: 'Profile'} }
      expect(JSON.parse(response.body)["otp_auth_key"]).to eq( otp_auth_key )
    end

    it "with duplicate mobile don't create new user, send pin to existing number", :show_in_doc do
      allow(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(user).to receive(:send_verification_pin)
      post :signup, format: 'json', user_auth: { mobile: mobile, first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: '1', address_type: 'Profile'} }
      expect(response.status).to eq(200)
    end

    it "with invalid mobile number" do
      post :signup, format: 'json', user_auth: { mobile: "123456", first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: '1', address_type: 'Profile'} }
      expect(JSON.parse(response.body)["errors"]).to eq( 'Mobile is invalid' )
    end

    it "with blank mobile number" do
      post :signup, format: 'json', user_auth: { mobile: "", first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: '1', address_type: 'Profile'} }
      expect(JSON.parse(response.body)["errors"]).to eq( "Mobile can't be blank. Mobile is invalid" )
    end

  end

  context "verify" do
    context "with successful authentication" do
      it 'should allow access to user after signed-in', :show_in_doc do
        set_donor_app_header
        allow(controller.send(:warden)).to receive(:authenticate).with(:pin).and_return(user)
        allow(controller.send(:warden)).to receive(:authenticated?).and_return(true)
        expect(controller).to receive(:generate_token).with(user_id: user.id).and_return(jwt_token)
        post :verify, format: 'json', otp_auth_key: otp_auth_key, pin: '1234'
        expect(JSON.parse(response.body)["jwt_token"]).to eq(jwt_token)
        expect(response.status).to eq(200)
      end

      it 'should return unprocessable entity if donor is accessing admin app', :show_in_doc do
        allow(controller.send(:warden)).to receive(:authenticate).with(:pin).and_return(user)
        allow(controller.send(:warden)).to receive(:authenticated?).and_return(true)
        expect(controller).to receive(:app_name).and_return(ADMIN_APP)
        post :verify, format: 'json', otp_auth_key: otp_auth_key, pin: '1234'
        expect(JSON.parse(response.body)["errors"]["pin"]).to eq(I18n.t('auth.invalid_pin'))
        expect(response.status).to eq(422)
      end
    end

    context "with unsucessful authentication" do
      it 'should return unprocessable entity' do
        allow(controller.send(:warden)).to receive(:authenticate).with(:pin).and_return(nil)
        allow(controller.send(:warden)).to receive(:authenticated?).and_return(false)
        post :verify, format: 'json', otp_auth_key: otp_auth_key, pin: '1234'
        expect(JSON.parse(response.body)["errors"]["pin"]).to eq(I18n.t('auth.invalid_pin'))
        expect(response.status).to eq(422)
      end
    end
  end

  context "send_pin" do
    it 'should find user by mobile', :show_in_doc do
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(user).to receive(:send_verification_pin)
      expect(controller).to receive(:otp_auth_key_for).with(user).and_return( otp_auth_key )
      expect(controller).to receive(:app_name).and_return(DONOR_APP)
      post :send_pin, mobile: mobile

      body = JSON.parse(response.body)
      expect(body['otp_auth_key']).to eql( otp_auth_key )
    end

    it "where user does not exist" do
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(nil)
      expect(user).to_not receive(:send_verification_pin)
      expect(controller).to receive(:otp_auth_key_for).with(nil).and_return( otp_auth_key )
      post :send_pin, mobile: mobile
      body = JSON.parse(response.body)
      expect(body['otp_auth_key']).to eql( otp_auth_key )
    end

    it 'should not send pin if donor logging into admin', :show_in_doc do
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(user).to_not receive(:send_verification_pin)
      expect(controller).to receive(:otp_auth_key_for).with(user).and_return( otp_auth_key )
      expect(controller).to receive(:app_name).and_return(ADMIN_APP)
      post :send_pin, mobile: mobile
      body = JSON.parse(response.body)
      expect(body['otp_auth_key']).to eql( otp_auth_key )
    end

    context "where mobile is" do
      it 'empty' do
        expect(User).to_not receive(:find_by_mobile)
        expect(user).to_not receive(:send_verification_pin)
        expect(controller).to_not receive(:otp_auth_key_for)
        post :send_pin, mobile: ""
        expect(response.status).to eq(422)
        body = JSON.parse(response.body)
        expect(body['errors']).to eql( "Mobile is invalid" )
      end
      it "not +852..." do
        expect(User).to_not receive(:find_by_mobile)
        expect(user).to_not receive(:send_verification_pin)
        expect(controller).to_not receive(:otp_auth_key_for)
        post :send_pin, mobile: "+9101234567"
        expect(response.status).to eq(422)
        body = JSON.parse(response.body)
        expect(body['errors']).to eql( "Mobile is invalid" )
      end
    end
  end

  context 'verify warden' do
    it 'warden object' do
      expect(controller.send(:warden)).to eq(request.env["warden"])
    end
  end

  describe "GET current_user_profile" do
    before { generate_and_set_token(user) }

    it "returns 200" do
      get :current_user_profile
      expect(response.status).to eq(200)
    end

    it "returns serialized user", :show_in_doc do
      get :current_user_profile
      expect(response.body).to eq(serialized_user)
    end
  end

end
