require 'rails_helper'
RSpec.describe Api::V1::AuthenticationController, type: :controller do

  let(:user)   { create(:user_with_token) }
  let(:supervisor) { create(:user_with_token, :supervisor, :with_organisation) }
  let(:charity_user) { create(:user_with_token, :with_multiple_roles_and_permissions,
    roles_and_permissions: { 'Charity' => ['can_login_to_browse']}) }
  let(:order_fulfilment) { create(:user_with_token, :with_multiple_roles_and_permissions,
    roles_and_permissions: { 'Order fulfilment' => ['can_login_to_stock']} )}
  let(:pin)    { user.most_recent_token[:otp_code] }
  let(:mobile) { generate(:mobile) }
  let(:mobile1) { generate(:mobile) }
  let(:otp_auth_key) { "/JqONEgEjrZefDV3ZIQsNA==" }
  let(:jwt_token)    { Token.new.generate }
  let(:serialized_user) { JSON.parse(Api::V1::UserProfileSerializer.new(user).as_json.to_json) }
  let(:parsed_body) { JSON.parse(response.body) }

  context "signup" do
    it 'new user successfully', :show_in_doc do
      expect_any_instance_of(User).to receive(:send_verification_pin)
      expect(controller).to receive(:otp_auth_key_for_user).and_return(otp_auth_key)
      post :signup, format: 'json', user_auth: { mobile: mobile, first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: '1', address_type: 'Profile'} }
      expect(parsed_body["otp_auth_key"]).to eq( otp_auth_key )
    end

    it "with duplicate mobile don't create new user, send pin to existing number", :show_in_doc do
      allow(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(user).to receive(:send_verification_pin)
      post :signup, format: 'json', user_auth: { mobile: mobile, first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: '1', address_type: 'Profile'} }
      expect(response.status).to eq(200)
    end

    it "with invalid mobile number" do
      post :signup, format: 'json', user_auth: { mobile: "123456", first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: '1', address_type: 'Profile'} }
      expect(parsed_body["errors"]).to eq( 'Mobile is invalid' )
    end

    it "with blank mobile number" do
      post :signup, format: 'json', user_auth: { mobile: "", first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: '1', address_type: 'Profile'} }
      expect(parsed_body["errors"]).to eq( "Mobile can't be blank. Mobile is invalid" )
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
        expect(parsed_body["jwt_token"]).to eq(jwt_token)
        expect(parsed_body["user"]).to eq(serialized_user)
        expect(response.status).to eq(200)
      end

      it 'should return unprocessable entity if donor is accessing admin app', :show_in_doc do
        set_admin_app_header
        allow(controller.send(:warden)).to receive(:authenticate).with(:pin).and_return(user)
        allow(controller.send(:warden)).to receive(:authenticated?).and_return(true)
        expect(controller).to receive(:app_name).and_return(ADMIN_APP).twice
        post :verify, format: 'json', otp_auth_key: otp_auth_key, pin: '1234'
        expect(parsed_body["errors"]["pin"]).to eq(I18n.t('auth.invalid_pin'))
        expect(response.status).to eq(422)
      end

      it 'returns unprocessable entity if donor is accessing stock app', :show_in_doc do
        set_stock_app_header
        allow(controller.send(:warden)).to receive(:authenticate).with(:pin).and_return(user)
        allow(controller.send(:warden)).to receive(:authenticated?).and_return(true)
        expect(controller).to receive(:app_name).and_return(STOCK_APP).twice
        post :verify, format: 'json', otp_auth_key: otp_auth_key, pin: '1234'
        expect(parsed_body["errors"]["pin"]).to eq(I18n.t('auth.invalid_pin'))
        expect(response.status).to eq(422)
      end

      it 'allows user with order fulfilment user to access stock after sign-in', :show_in_doc do
        set_stock_app_header
        allow(controller.send(:warden)).to receive(:authenticate).with(:pin).and_return(order_fulfilment)
        allow(controller.send(:warden)).to receive(:authenticated?).and_return(true)
        expect(controller).to receive(:generate_token).with(user_id: order_fulfilment.id).and_return(jwt_token)
        post :verify, format: 'json', otp_auth_key: otp_auth_key, pin: '1234'
        expect(parsed_body["jwt_token"]).to eq(jwt_token)
        expect(response.status).to eq(200)
      end
    end

    context "with unsucessful authentication" do
      it 'should return unprocessable entity' do
        allow(controller.send(:warden)).to receive(:authenticate).with(:pin).and_return(nil)
        allow(controller.send(:warden)).to receive(:authenticated?).and_return(false)
        post :verify, format: 'json', otp_auth_key: otp_auth_key, pin: '1234'
        expect(parsed_body["errors"]["pin"]).to eq(I18n.t('auth.invalid_pin'))
        expect(response.status).to eq(422)
      end
    end
  end

  context "send_pin" do
    it 'should find user by mobile', :show_in_doc do
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(user).to receive(:send_verification_pin)
      expect(controller).to receive(:otp_auth_key_for_user).and_return( otp_auth_key )
      expect(controller).to receive(:app_name).and_return(DONOR_APP)
      post :send_pin, mobile: mobile
      expect(response.status).to eq(200)
      expect(parsed_body['otp_auth_key']).to eql( otp_auth_key )
    end

    it "where user does not exist" do
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(nil)
      expect(user).to_not receive(:send_verification_pin)
      expect(controller).to receive(:otp_auth_key_for_user).and_return( otp_auth_key )
      post :send_pin, mobile: mobile
      expect(parsed_body['otp_auth_key']).to eql( otp_auth_key )
    end

    it 'do not send pin if donor login into admin', :show_in_doc do
      set_admin_app_header
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(user).to_not receive(:send_verification_pin)
      expect(controller).to receive(:app_name).and_return(ADMIN_APP)
      post :send_pin, mobile: mobile
      expect(response.status).to eq(401)
      expect(parsed_body["error"]).to eq("You are not authorized.")
      expect(parsed_body['otp_auth_key']).to eql( nil )
    end

    context "register_user_and_send_pin" do
      it 'if user exists in system but do not have any organisation assigned', :show_in_doc do
        expect(User).to receive(:find_or_create_user).with(mobile).and_return(user)
        expect(controller).to receive(:otp_auth_key_for_user).and_return(otp_auth_key)
        post :register_user_and_send_pin, mobile: mobile
        expect(response.status).to eq(200)
        expect(parsed_body['otp_auth_key']).to eql( otp_auth_key )
      end

      it 'if user exists and have organisation assigned', :show_in_doc do
        expect(User).to receive(:find_or_create_user).with(mobile).and_return(supervisor)
        expect(controller).to receive(:otp_auth_key_for_user).and_return(otp_auth_key)
        post :register_user_and_send_pin, mobile: mobile
        expect(response.status).to eq(200)
        expect(parsed_body['otp_auth_key']).to eql( otp_auth_key )
      end

      it 'if mobile number does not exist it creates new user', :show_in_doc do
        post :register_user_and_send_pin, mobile: mobile1
        expect(response.status).to eq(200)
        expect(User.count).to eql(2)
      end

      it 'if existing user with charity role logging into Browse', :show_in_doc do
        expect(User).to receive(:find_or_create_user).with(mobile).and_return(charity_user)
        expect(controller).to receive(:otp_auth_key_for_user).and_return(otp_auth_key)
        post :register_user_and_send_pin, mobile: mobile
        expect(response.status).to eq(200)
        expect(parsed_body['otp_auth_key']).to eql( otp_auth_key )
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
  end

  # High level smoke tests to ensure correct channels are returned
  context "current_user_channels" do

    context 'donor app' do
      before { generate_and_set_token(user) }
      before { set_donor_app_header }
      let(:expected_channels) { ["user_#{user.id}"] }
      it { expect(controller.send(:current_user_channels)).to eql(expected_channels) }
    end

    context 'admin app with supervisor role' do
      before do
        generate_and_set_token(supervisor)
        set_admin_app_header
      end
      let(:expected_channels) { ["user_#{supervisor.id}_admin", 'supervisor'] }
      it { expect(controller.send(:current_user_channels)).to eql(expected_channels) }
    end

    context 'stock app with order_fulfilment role' do
      before do
        generate_and_set_token(order_fulfilment)
        set_stock_app_header
      end
      let(:expected_channels) { ["user_#{order_fulfilment.id}_stock", 'order_fulfilment'] }
      it { expect(controller.send(:current_user_channels)).to eql(expected_channels) }
    end

    context 'browse app with charity role' do
      before do
        generate_and_set_token(charity_user)
        set_browse_app_header
      end
      let(:expected_channels) { ["user_#{charity_user.id}_browse"] }
      it { expect(controller.send(:current_user_channels)).to eql(expected_channels) }
    end

  end

end
