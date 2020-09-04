require 'rails_helper'
RSpec.describe Api::V2::AuthenticationController, type: :controller do

  let(:user) { create(:user, :with_token) }
  let(:mobile) { generate(:mobile) }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:pin)    { user.most_recent_token[:otp_code] }
  let(:otp_auth_key) { "/JqONEgEjrZefDV3ZIQsNA==" }
  
  context "send_pin" do
    it 'should find user by mobile', :show_in_doc do
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(AuthenticationService).to receive(:send_pin)
      expect(AuthenticationService).to receive(:otp_auth_key_for).and_return(otp_auth_key)
      expect(controller).to receive(:app_name).and_return(DONOR_APP).at_least(:once)
      post :send_pin, mobile: mobile
      expect(response.status).to eq(200)
      expect(parsed_body['otp_auth_key']).to eql( otp_auth_key )
    end

    it "where user does not exist" do
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(nil)
      expect(user).to_not receive(:send_verification_pin)
      expect(controller).to receive(:otp_auth_key_for).and_return( otp_auth_key )
      post :send_pin, mobile: mobile
      expect(parsed_body['otp_auth_key']).to eql( otp_auth_key )
    end

    it 'do not send pin if donor login into admin', :show_in_doc do
      set_admin_app_header
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(user).to_not receive(:send_verification_pin)
      expect(controller).to receive(:app_name).and_return(ADMIN_APP).at_least(:once)
      post :send_pin, mobile: mobile
      expect(response.status).to eq(401)
      expect(parsed_body["error"]).to eq("You are not authorized.")
      expect(parsed_body['otp_auth_key']).to eql( nil )
    end

    context "signup for Browse app" do
      it 'sends otp_auth_key if user exists in system with no organisation assigned', :show_in_doc do
        allow(User).to receive(:find_by_mobile).with(mobile).and_return(user)
        expect(user).to receive(:send_verification_pin)
        post :signup, format: 'json', user_auth: { mobile: mobile, address_attributes: {district_id: '1', address_type: 'Profile'} }
        expect(response.status).to eq(200)
      end

      it 'sends otp_auth_key if user exists and has organisation assigned', :show_in_doc do
        allow(User).to receive(:find_by_mobile).with(mobile).and_return(supervisor)
        expect(supervisor).to receive(:send_verification_pin)
        post :signup, format: 'json', user_auth: { mobile: mobile, address_attributes: {district_id: '1', address_type: 'Profile'} }
        expect(response.status).to eq(200)
      end

      it 'sends otp_auth_key if existing charity_user logging into Browse', :show_in_doc do
        allow(User).to receive(:find_by_mobile).with(mobile).and_return(charity_user)
        expect(charity_user).to receive(:send_verification_pin)
        post :signup, format: 'json', user_auth: { mobile: mobile, address_attributes: {district_id: '1', address_type: 'Profile'} }
        expect(response.status).to eq(200)
      end

      it 'sends otp_auth_key if existing charity_user logging into Browse', :show_in_doc do
        allow(User).to receive(:find_by_mobile).with(mobile).and_return(charity_user)
        expect(charity_user).to receive(:send_verification_pin)
        post :signup, format: 'json', user_auth: { mobile: mobile, address_attributes: {district_id: '1', address_type: 'Profile'} }
        expect(response.status).to eq(200)
      end
    end

    context "where mobile is" do
      it 'empty' do
        expect(User).to_not receive(:find_by_mobile)
        expect(user).to_not receive(:send_verification_pin)
        expect(controller).to_not receive(:otp_auth_key_for)
        post :send_pin, mobile: ""
        expect(response.status).to eq(422)
        expect(parsed_body['errors']).to eql( "Mobile is invalid" )
      end

      it "not +852..." do
        expect(User).to_not receive(:find_by_mobile)
        expect(user).to_not receive(:send_verification_pin)
        expect(controller).to_not receive(:otp_auth_key_for)
        post :send_pin, mobile: "+9101234567"
        expect(response.status).to eq(422)
        expect(parsed_body['errors']).to eql( "Mobile is invalid" )
      end
    end
  end

  describe 'Hasura authentication' do
    context 'as a guest' do
      it 'returns a 401' do
        post :hasura
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated' do
      before { generate_and_set_token(user) }

      it 'returns an authentication token' do
        post :hasura
        expect(response.status).to eq(200)
        expect(parsed_body["token"]).not_to be_nil
      end
    end
  end
end



