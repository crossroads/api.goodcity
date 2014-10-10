require 'rails_helper'
RSpec.describe Api::V1::AuthenticationController, type: :controller do

  let(:user)   { create(:user_with_token) }
  let(:pin)    { user.most_recent_token[:otp_code] }
  let(:mobile) { "+919930001948" }

  context "signup" do
    it 'new user successfully', :show_in_doc do
      expect_any_instance_of(User).to receive(:send_verification_pin)
      post :signup, format: 'json', user_auth: { mobile: mobile, first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: '1', address_type: 'Profile'} }
      expect(JSON.parse(response.body)["message"]).to eq(I18n.t(:success))
    end

    it 'is invalid (duplicate mobile)', :show_in_doc do
      create :user, mobile: '+85212345678'
      post :signup, format: 'json', user_auth: { mobile: '+85212345678', first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: '1', address_type: 'Profile'} }
      expect(JSON.parse(response.body)["errors"]).to eq("Mobile has already been taken")
    end
  end

  context "verify" do
    it 'should allow access to user after signed-in', :show_in_doc do
      allow(controller.send(:warden)).to receive(:authenticate!).with(:pin).and_return(user, true)
      allow(controller.send(:warden)).to receive(:authenticated?).and_return(true)
      post :verify, format: 'json', mobile: '+85212345678', pin: '1234'
      expect(response.message).to eq("OK")
      expect(response.status).to eq(200)
    end
    it 'empty pin'
    it 'empty mobile'
  end

  context "send_pin" do
    it 'should find user by mobile', :show_in_doc do
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(user).to receive(:send_verification_pin)
      post :send_pin, mobile: mobile
    end
    it 'empty mobile', :show_in_doc do
    end
    it 'no user found with valid mobile'
  end

  context 'verify warden' do
    it 'warden object' do
      expect(controller.send(:warden)).to eq(request.env["warden"])
    end
  end

end
