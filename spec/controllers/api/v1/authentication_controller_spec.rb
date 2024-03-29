require 'rails_helper'
RSpec.describe Api::V1::AuthenticationController, type: :controller do

  let(:user)   { create(:user, :with_token) }
  let(:supervisor) { create(:user, :with_token, :supervisor, :charity) }
  let(:charity_user) { create(:user, :with_token, :charity) }
  let(:order_fulfilment) { create(:user, :with_token, :with_order_fulfilment_role, :with_can_login_to_stock_permission) }
  let(:pin)    { user.most_recent_token[:otp_code] }
  let(:mobile) { generate(:mobile) }
  let(:mobile1) { generate(:mobile) }
  let(:district_id) { create(:district).id.to_s }

  let(:otp_auth_key) { "/JqONEgEjrZefDV3ZIQsNA==" }
  let(:jwt_token)    { Token.new.generate({}) }
  let(:serialized_user) { JSON.parse(Api::V1::UserProfileSerializer.new(user).as_json.to_json) }
  let(:parsed_body) { JSON.parse(response.body) }

  context "signup" do
    it 'new user successfully', :show_in_doc do
      expect_any_instance_of(User).to receive(:send_verification_pin)
      expect(AuthenticationService).to receive(:otp_auth_key_for).and_return(otp_auth_key)
      post :signup, params: { user_auth: { mobile: mobile, first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: district_id, address_type: 'Profile'} } }
      expect(parsed_body["otp_auth_key"]).to eq( otp_auth_key )
    end

    it "with duplicate mobile don't create new user, send pin to existing number", :show_in_doc do
      allow(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(user).to receive(:send_verification_pin)
      post :signup, params: { user_auth: { mobile: mobile, first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: district_id, address_type: 'Profile'} } }
      expect(response.status).to eq(200)
    end

    it "with invalid mobile number" do
      post :signup, params: { user_auth: { mobile: "123456", first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: district_id, address_type: 'Profile'} } }
      expect(parsed_body["errors"]).to eq( 'Mobile is invalid' )
    end

    it "with blank mobile number" do
      post :signup, params: { user_auth: { mobile: "", first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: district_id, address_type: 'Profile'} } }
      expect(parsed_body["errors"]).to eq("Mobile can't be blank")
    end

    context 'email' do
      before do
        set_browse_app_header
      end
      context 'when email is case-sensitive duplicate' do
        it 'does not create a new user' do
          user = create(:user)
          expect { post :signup, params: { user_auth: { mobile: '', email: user.email, first_name: '', last_name: '', address_attributes: { district_id: '', address_type: '' } } } }.not_to change{ User.count }
        end
      end

      context 'when email is unique' do
        it 'creates a new user' do
          user = build(:user)

          expect { post :signup, params: { user_auth: { mobile: '', email: user.email, first_name: '', last_name: '', address_attributes: { district_id: '', address_type: '' } } } }.to change{ User.count }.by(1)
        end
      end
    end
  end

  context "otp_auth_key" do
    before { set_browse_app_header }
    it "is recycled if the user phone number is valid" do
      current_otp_auth_key = user.most_recent_token.otp_auth_key
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(AuthenticationService).to receive(:otp_auth_key_for).with(user,refresh: true).and_return(otp_auth_key)
      post :send_pin, params: { mobile: mobile }
      expect(response.status).to eq(200)
      expect(parsed_body['otp_auth_key']).to_not eq(current_otp_auth_key)
    end
  end

  context "verify" do
    context "with successful authentication" do
      it 'should allow access to user and verify email after signed in on browse', :show_in_doc do
        set_browse_app_header
        auth_token = AuthToken.new
        allow(AuthToken).to receive(:find_by_otp_auth_key).and_return(auth_token)
        allow(auth_token).to receive(:user).and_return(user)
        allow(auth_token).to receive(:authenticate_otp).and_return(true)
        expect(controller).to receive(:generate_token).with(user_id: user.id).and_return(jwt_token)
        post :verify, params: { otp_auth_key: otp_auth_key, pin: '1234', pin_for: 'email' }
        expect(parsed_body["user"]["user_profile"]["is_email_verified"]).to be_truthy
        expect(parsed_body["jwt_token"]).to eq(jwt_token)
        expect(parsed_body["user"]).to eq(serialized_user)
        expect(response.status).to eq(200)
      end

      it 'should allow access to user after signed-in', :show_in_doc do
        set_donor_app_header
        auth_token = AuthToken.new
        allow(AuthToken).to receive(:find_by_otp_auth_key).and_return(auth_token)
        allow(auth_token).to receive(:user).and_return(user)
        allow(auth_token).to receive(:authenticate_otp).and_return(true)
        expect(controller).to receive(:generate_token).with(user_id: user.id).and_return(jwt_token)
        post :verify, params: { otp_auth_key: otp_auth_key, pin: '1234' }
        expect(parsed_body["user"]["user_profile"]["is_mobile_verified"]).to be_truthy
        expect(parsed_body["jwt_token"]).to eq(jwt_token)
        expect(parsed_body["user"]).to eq(serialized_user)
        expect(response.status).to eq(200)
      end

      it 'should return unprocessable entity if donor is accessing admin app', :show_in_doc do
        set_admin_app_header
        expect(AuthenticationService).to receive(:authenticate).with(anything, strategy: :pin).and_return(user)
        expect(controller).to receive(:app_name).and_return(ADMIN_APP).at_least(:once)
        post :verify, params: { otp_auth_key: otp_auth_key, pin: '1234' }
        expect(parsed_body["errors"]["pin"]).to eq(I18n.t('auth.invalid_pin'))
        expect(response.status).to eq(422)
      end

      it 'should allow access to guest-user if he is accessing stock app', :show_in_doc do
        set_stock_app_header
        expect(AuthenticationService).to receive(:authenticate).with(anything, strategy: :pin).and_return(user)
        expect(controller).to receive(:app_name).and_return(STOCK_APP).at_least(:once)
        post :verify, params: { otp_auth_key: otp_auth_key, pin: '1234' }

        expect(response.status).to eq(200)
      end

      it 'allows user with order fulfilment user to access stock after sign-in', :show_in_doc do
        set_stock_app_header
        expect(AuthenticationService).to receive(:authenticate).with(anything, strategy: :pin).and_return(order_fulfilment)
        expect(controller).to receive(:generate_token).with(user_id: order_fulfilment.id).and_return(jwt_token)
        post :verify, params: { otp_auth_key: otp_auth_key, pin: '1234' }
        expect(parsed_body["jwt_token"]).to eq(jwt_token)
        expect(response.status).to eq(200)
      end
    end

    context "with unsucessful authentication" do
      it 'should return unprocessable entity' do
        expect(AuthenticationService).to receive(:authenticate).with(anything, strategy: :pin).and_return(nil)

        post :verify, params: { otp_auth_key: otp_auth_key, pin: '1234' }
        expect(parsed_body["errors"]["pin"]).to eq(I18n.t('auth.invalid_pin'))
        expect(response.status).to eq(422)
      end
    end
  end

  context "send_pin" do

    it 'should find user by mobile', :show_in_doc do
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(AuthenticationService).to receive(:otp_auth_key_for).and_return( otp_auth_key )
      expect(user).to receive(:send_verification_pin)
      expect(controller).to receive(:app_name).and_return(DONOR_APP).at_least(:once)
      post :send_pin, params: { mobile: mobile }
      expect(response.status).to eq(200)
      expect(parsed_body['otp_auth_key']).to eql( otp_auth_key )
    end

    it "where user does not exist" do
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(nil)
      expect(user).to_not receive(:send_verification_pin)
      expect(AuthenticationService).not_to receive(:otp_auth_key_for)
      expect(AuthenticationService).to receive(:fake_otp_auth_key).and_return( otp_auth_key )
      post :send_pin, params: { mobile: mobile }
      expect(parsed_body['otp_auth_key']).to eql( otp_auth_key )
    end

    it 'do not send pin if donor login into admin', :show_in_doc do
      set_admin_app_header
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(user).to_not receive(:send_verification_pin)
      expect(controller).to receive(:app_name).and_return(ADMIN_APP).at_least(:once)
      post :send_pin, params: { mobile: mobile }
      expect(response.status).to eq(401)
      expect(parsed_body["error"]).to eq("You are not authorized.")
      expect(parsed_body['otp_auth_key']).to eql( nil )
    end

    context "signup for Browse app" do
      it 'sends otp_auth_key if user exists in system with no organisation assigned', :show_in_doc do
        allow(User).to receive(:find_by_mobile).with(mobile).and_return(user)
        expect(user).to receive(:send_verification_pin)
        post :signup, params: { user_auth: { mobile: mobile, address_attributes: {district_id: district_id, address_type: 'Profile'} } }
        expect(response.status).to eq(200)
      end

      it 'sends otp_auth_key if user exists and has organisation assigned', :show_in_doc do
        allow(User).to receive(:find_by_mobile).with(mobile).and_return(supervisor)
        expect(supervisor).to receive(:send_verification_pin)
        post :signup, params: { user_auth: { mobile: mobile, address_attributes: {district_id: district_id, address_type: 'Profile'} } }
        expect(response.status).to eq(200)
      end

      it 'sends otp_auth_key if existing charity_user logging into Browse', :show_in_doc do
        allow(User).to receive(:find_by_mobile).with(mobile).and_return(charity_user)
        expect(charity_user).to receive(:send_verification_pin)
        post :signup, params: { user_auth: { mobile: mobile, address_attributes: {district_id: district_id, address_type: 'Profile'} } }
        expect(response.status).to eq(200)
      end

      it 'sends otp_auth_key if existing charity_user logging into Browse', :show_in_doc do
        allow(User).to receive(:find_by_mobile).with(mobile).and_return(charity_user)
        expect(charity_user).to receive(:send_verification_pin)
        post :signup, params: { user_auth: { mobile: mobile, address_attributes: {district_id: district_id, address_type: 'Profile'} } }
        expect(response.status).to eq(200)
      end
    end

    context "where mobile is" do
      it 'empty' do
        expect(User).to_not receive(:find_by_mobile)
        expect(user).to_not receive(:send_verification_pin)
        expect(AuthenticationService).not_to receive(:otp_auth_key_for)
        post :send_pin, params: { mobile: "" }
        expect(response.status).to eq(422)
        expect(parsed_body['errors']).to eql( "Mobile is invalid" )
      end

      it "not +852..." do
        expect(User).to_not receive(:find_by_mobile)
        expect(user).to_not receive(:send_verification_pin)
        expect(AuthenticationService).not_to receive(:otp_auth_key_for)
        post :send_pin, params: { mobile: "+9101234567" }
        expect(response.status).to eq(422)
        expect(parsed_body['errors']).to eql( "Mobile is invalid" )
      end
    end
  end

  describe 'signup_and_send_pin' do
    context "Login for stock app" do
      before { set_stock_app_header }

      it "should return success where user does not exist" do
        guest_mobile = "+85290990999"
        expect(User).to receive(:find_by_mobile).with(guest_mobile).and_return(nil)
        expect(AuthenticationService).to receive(:otp_auth_key_for).and_return( otp_auth_key )
        expect(controller).to receive(:app_name).and_return(STOCK_APP).at_least(:once)

        expect {
          post :signup_and_send_pin, params: { mobile: guest_mobile }
        }.to change(User, :count).by(+1)

        expect(parsed_body['otp_auth_key']).to eql( otp_auth_key )
      end

      it "should return success where user has expired-role" do
        stock_user = create(:user, :"with_stock_fulfilment_role", :with_can_login_to_stock_permission, role_expiry: 5.days.ago)

        expect(User).to receive(:find_by_mobile).with(stock_user.mobile).and_return(stock_user)
        expect(AuthenticationService).to receive(:otp_auth_key_for).and_return( otp_auth_key )
        expect(controller).to receive(:app_name).and_return(STOCK_APP).at_least(:once)

        post :signup_and_send_pin, params: { mobile: stock_user.mobile }

        expect(parsed_body['otp_auth_key']).to eql( otp_auth_key )

      end
    end
  end

  describe "GET current_user_profile" do
    before { generate_and_set_token(user) }

    it "returns 200" do
      get :current_user_profile
      expect(response.status).to eq(200)
    end

    context 'if preferred_language is not set for the user' do
      before { user.update(preferred_language: nil) }

      it 'updates preferred language based on the locale' do
        request.headers.merge!({ 'Accept-Language': 'zh-tw' })
        get :current_user_profile
        expect(user.reload.preferred_language).to eq('zh-tw')
      end
    end

    context 'if user already has a preferred_language set'do
      before(:each) { user.update(preferred_language: 'en') }

      context 'if the user changes preferred_language in the UI' do
        it 'updates preferred language based on the locale' do
          request.headers.merge!({ 'Accept-Language': 'zh-tw' })
          expect {
            get :current_user_profile
          }.to change{ user.reload.preferred_language }.to('zh-tw')
        end
      end

      context 'if the user does not changes preferred_language in UI' do
        it 'does not affect the field' do
          request.headers.merge!({ 'Accept-Language': 'en' })
          expect {
            get :current_user_profile
          }.to_not change{ user.reload.preferred_language }
        end
      end
    end

    context 'donor app' do
      before do
        set_donor_app_header
      end

      it 'printers node should not be present in the response' do
        get :current_user_profile
        expect(JSON.parse(response.body).keys).not_to include('printers')
      end
    end

    context 'donor app with supervisor logged in' do
      before do
        generate_and_set_token(supervisor)
        set_donor_app_header
      end

      it 'printers node should not be present in the response' do
        get :current_user_profile
        expect(JSON.parse(response.body).keys).not_to include('printers')
      end
    end

    context 'admin app' do
      before do
        generate_and_set_token(supervisor)
        set_admin_app_header
      end

      it 'printers node should be present in the response' do
        get :current_user_profile
        expect(JSON.parse(response.body).keys).to include('printers_users')
      end
    end

    context 'stock app' do
      before do
        generate_and_set_token(supervisor)
        set_stock_app_header
      end

      it 'printers node should be present in the response' do
        get :current_user_profile
        expect(JSON.parse(response.body).keys).to include("printers_users")
      end
    end
  end

  # High level smoke tests to ensure correct channels are returned
  context "current_user_rooms" do
    context 'donor app' do
      before do
        generate_and_set_token(user)
        set_donor_app_header
        get :current_user_rooms
      end
      let(:expected_channels) { ["user_#{user.id}"] }
      it { expect(parsed_body).to eql(expected_channels) }
    end

    context 'admin app with supervisor role' do
      before do
        generate_and_set_token(supervisor)
        set_admin_app_header
        get :current_user_rooms
      end
      let(:expected_channels) { ["user_#{supervisor.id}_admin", 'supervisor'] }
      it { expect(parsed_body).to eql(expected_channels) }
    end

    context 'stock app with order_fulfilment role' do
      before do
        generate_and_set_token(order_fulfilment)
        set_stock_app_header
        get :current_user_rooms
      end
      let(:expected_channels) { ["user_#{order_fulfilment.id}_stock", 'order_fulfilment', 'inventory'] }
      it { expect(parsed_body).to eql(expected_channels) }
    end

    context 'browse app with charity role' do
      before do
        generate_and_set_token(charity_user)
        set_browse_app_header
        get :current_user_rooms
      end
      let(:expected_channels) { ["user_#{charity_user.id}_browse", "browse"] }
      it { expect(parsed_body).to eql(expected_channels) }
    end

    context 'browse app with anonymous user' do
      before do
        set_browse_app_header
        get :current_user_rooms
      end
      it { expect(parsed_body).to eql(["browse"]) }
    end

    context 'stock app with anonymous user' do
      before do
        set_stock_app_header
        get :current_user_rooms
      end
      it { expect(parsed_body).to eql([]) }
    end
  end
end
