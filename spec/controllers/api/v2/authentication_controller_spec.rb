require 'rails_helper'
RSpec.describe Api::V2::AuthenticationController, type: :controller do

  let(:user)          { create(:user, :with_token, :with_supervisor_role) }
  let(:mobile)        { generate(:mobile) }
  let(:email)         { 'some@email.com' }
  let(:parsed_body)   { JSON.parse(response.body) }
  let(:pin)           { user.most_recent_token[:otp_code] }
  let(:otp_auth_key)  { "l/Ed2XSaihKD0u6RepsaaA==" }
  let(:district)      { create(:district) }

  def parse_jwt(jwt)
    Token.new(bearer: jwt)
  end

  context "signup" do
    let(:signup_params) {
      { mobile: mobile, email: email, first_name: "Jake", last_name: "Deamon", address_attributes: {district_id: district.id.to_s, address_type: 'Profile'} }
    }
    let(:signup_email_params) { signup_params.except(:mobile) }
    let(:signup_mobile_params) { signup_params.except(:email) }

    it 'creates new user successfully from a mobile number', :show_in_doc do
      expect(AuthenticationService).to receive(:send_pin)
      expect(AuthenticationService).to receive(:otp_auth_key_for).and_return(otp_auth_key)

      expect {
        post :signup, format: 'json', params: { user_auth: signup_mobile_params }
      }.to change(User, :count).by(1)

      expect(response.status).to eq(201)

      user = User.last
      expect(user.mobile).to eq(mobile)
      expect(user.email).to eq(nil)
      expect(user.first_name).to eq("Jake")
      expect(user.last_name).to eq("Deamon")
      expect(user.address.district).to eq(district)
      expect(user.address.address_type).to eq("Profile")
      expect(
        parse_jwt(parsed_body['otp_auth_key']).read('otp_auth_key')
      ).to eq(otp_auth_key)
    end

    it 'creates new user successfully from an email', :show_in_doc do
      expect(AuthenticationService).to receive(:send_pin)
      expect(AuthenticationService).to receive(:otp_auth_key_for).and_return(otp_auth_key)

      expect {
        post :signup, format: 'json', params: { user_auth: signup_email_params }
      }.to change(User, :count).by(1)

      expect(response.status).to eq(201)

      user = User.last
      expect(user.mobile).to eq(nil)
      expect(user.email).to eq(email)
      expect(user.first_name).to eq("Jake")
      expect(user.last_name).to eq("Deamon")
      expect(user.address.district).to eq(district)
      expect(user.address.address_type).to eq("Profile")
      expect(
        parse_jwt(parsed_body['otp_auth_key']).read('otp_auth_key')
      ).to eq(otp_auth_key)
    end

    it 'creates new user successfully from a mobile and an email', :show_in_doc do
      expect(AuthenticationService).to receive(:send_pin)
      expect(AuthenticationService).to receive(:otp_auth_key_for).and_return(otp_auth_key)

      expect {
        post :signup, format: 'json', params: { user_auth: signup_params }
      }.to change(User, :count).by(1)

      expect(response.status).to eq(201)

      user = User.last
      expect(user.mobile).to eq(mobile)
      expect(user.email).to eq(email)
      expect(user.first_name).to eq("Jake")
      expect(user.last_name).to eq("Deamon")
      expect(user.address.district).to eq(district)
      expect(user.address.address_type).to eq("Profile")
      expect(
        parse_jwt(parsed_body['otp_auth_key']).read('otp_auth_key')
      ).to eq(otp_auth_key)
    end

    it "logs in the user if his/her number already exists", :show_in_doc do
      existing_user = create(:user, mobile: mobile)

      expect(AuthenticationService).to receive(:send_pin).once
      expect(AuthenticationService).to receive(:otp_auth_key_for).with(existing_user).once.and_return(otp_auth_key)

      expect {
        post :signup, format: 'json', params: { user_auth: signup_mobile_params }
      }.not_to change(User, :count)

      expect(response.status).to eq(200)
      expect(
        parse_jwt(parsed_body['otp_auth_key']).read('otp_auth_key')
      ).to eq(otp_auth_key)
    end

    it "logs in the user if his/her email already exists (case insensitive)", :show_in_doc do
      existing_user = create(:user, email: email.upcase)

      expect(AuthenticationService).to receive(:send_pin).once
      expect(AuthenticationService).to receive(:otp_auth_key_for).with(existing_user).once.and_return(otp_auth_key)

      expect {
        post :signup, format: 'json', params: { user_auth: signup_email_params }
      }.not_to change(User, :count)

      expect(response.status).to eq(200)
      expect(
        parse_jwt(parsed_body['otp_auth_key']).read('otp_auth_key')
      ).to eq(otp_auth_key)
    end

    it "with invalid mobile number and no email" do
      post :signup, format: 'json', params: { user_auth: signup_params.merge({ mobile: '123456' }) }
      expect(response.status).to eq(422)
      expect(parsed_body["error"]).to match('Mobile is invalid')
    end

    it "with invalid email number and no mobile" do
      post :signup, format: 'json', params: { user_auth: signup_params.merge({ mobile: '', email: 'bad mail' }) }
      expect(response.status).to eq(422)
      expect(parsed_body["error"]).to match('Email is invalid')
    end

    it "with no mobile or email" do
      post :signup, format: 'json', params: { user_auth: signup_params.except(:mobile, :email) }
      expect(response.status).to eq(422)
      expect(parsed_body["error"]).to match("Param 'mobile/email' is required")
    end
  end

  context "send_pin" do
    it 'should find user by mobile', :show_in_doc do
      expect(User).to receive(:find_by_mobile).with(mobile).and_return(user)
      expect(AuthenticationService).to receive(:send_pin)
      expect(AuthenticationService).to receive(:otp_auth_key_for).and_return(otp_auth_key)
      expect(controller).to receive(:app_name).and_return(DONOR_APP).at_least(:once)
      post :send_pin, params: { mobile: mobile }
      expect(response.status).to eq(200)

      token = Token.new(bearer: parsed_body['otp_auth_key'])

      expect(token.read('otp_auth_key')).to eql( otp_auth_key )
      expect(token.read('pin_method')).to eql( 'mobile' )
    end

    it "where user does not exist" do
      expect(AuthenticationService).not_to receive(:send_pin)
      expect(AuthenticationService).not_to receive(:otp_auth_key_for)
      expect(AuthenticationService).to receive(:fake_otp_auth_key).once.and_return(otp_auth_key)

      post :send_pin, params: { mobile: mobile }
      expect(
        Token.new(bearer: parsed_body['otp_auth_key']).read('otp_auth_key')
      ).to eql( otp_auth_key )
    end

    context "where mobile is" do
      it 'empty' do
        expect(AuthenticationService).not_to receive(:send_pin)
        expect(AuthenticationService).not_to receive(:otp_auth_key_for)
        post :send_pin, params: { mobile: '123' }

        expect(response.status).to eq(422)
        expect(parsed_body["error"]).to eq("Mobile is invalid")
        expect(parsed_body['otp_auth_key']).to eql( nil )
      end

      it "not +852..." do
        expect(AuthenticationService).not_to receive(:send_pin)
        expect(AuthenticationService).not_to receive(:otp_auth_key_for)
        post :send_pin, params: { mobile: '+9101234567' }

        expect(response.status).to eq(422)
        expect(parsed_body["error"]).to eq("Mobile is invalid")
        expect(parsed_body['otp_auth_key']).to eql( nil )
      end
    end
  end

  context "verify" do
    let(:jwt_token) { Token.new.generate({}) }
    let(:jwt_otp) {
      Token.new.generate_otp_token({
        pin_method:     :mobile,
        otp_auth_key:   AuthenticationService.otp_auth_key_for(user)
      })
    }

    context "with successful authentication" do
      it 'should return a JWT token and the user data', :show_in_doc do
        params = { otp_auth_key: 'otp_auth_key', pin: '1234' }

        expect(AuthenticationService).to receive(:authenticate!).with(anything, strategy: :pin_jwt).and_return(user)
        expect(AuthenticationService).to receive(:generate_token).with(user, api_version: 2).and_return(jwt_token)

        post :verify, format: 'json', params: params
        expect(response.status).to eq(200)
        expect(parsed_body['jwt_token']).not_to be_nil
        expect(parsed_body["data"]["type"]).to eq("user")
        expect(parsed_body["data"]["id"]).to eq(user.id.to_s)
      end

      it 'verifies the mobile of the user' do
        expect(Token.new(bearer: jwt_otp).valid?).to eq(true)
        expect_any_instance_of(AuthToken).to receive(:authenticate_otp).and_return(true)

        expect {
          post :verify, format: 'json', params: { otp_auth_key: jwt_otp, pin: '1234' }
        }.to change { user.reload.is_mobile_verified }.from(false).to(true)
      end
    end

    context "with unsucessful authentication" do
      it 'should return unprocessable entity' do
        allow_any_instance_of(Goodcity::Authentication::Strategies::PinJwtStrategy).to receive(:valid?).and_return(true) # pretend the format of params is correct
        allow_any_instance_of(Goodcity::Authentication::Strategies::PinJwtStrategy).to receive(:lookup_auth_token).and_return(AuthToken.new) # pretend auth token is correct
        allow_any_instance_of(Goodcity::Authentication::Strategies::PinJwtStrategy).to receive(:valid_otp_code?).and_return(false) # pretend the pin is wrong
        expect(AuthenticationService).not_to receive(:generate_token)

        post :verify, format: 'json', params: { otp_auth_key: otp_auth_key, pin: '1234' }
        expect(parsed_body["error"]).to eq(I18n.t('auth.invalid_pin'))
        expect(response.status).to eq(401)
      end
    end
  end

  describe 'Hasura authentication' do
    context 'as a guest' do
      it 'returns a 401' do
        post :hasura
        expect(parsed_body).to eq({
          "error"  => "Invalid token",
          "type"   => "UnauthorizedError",
          "status" => 401
        })
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

  describe 'Goodchat authentication' do
    let(:donor)         { create :user }
    let(:charity)       { create :user, :charity }
    let(:reviewer)      { create(:user, :reviewer) }
    let(:supervisor)    { create(:user, :with_token, :with_supervisor_role) }
    let(:stock_manager) { create(:user, :with_token, :with_stock_administrator_role) }

    context 'as a guest' do
      it 'returns a 401' do
        post :goodchat
        expect(parsed_body).to eq({
          "error"  => "Invalid token",
          "type"   => "UnauthorizedError",
          "status" => 401
        })
      end
    end

    context 'when authenticated' do
      context 'as a donor' do
        before { generate_and_set_token(donor) }

        it 'returns a 403' do
          post :goodchat
          expect(parsed_body).to eq({
            "error"  => "Access Denied",
            "type"   => "AccessDeniedError",
            "status" => 403
          })
        end
      end

      context 'as a charity' do
        before { generate_and_set_token(charity) }

        it 'returns a 403' do
          post :goodchat
          expect(parsed_body).to eq({
            "error"  => "Access Denied",
            "type"   => "AccessDeniedError",
            "status" => 403
          })
        end
      end


      context 'as a reviewer' do
        before { generate_and_set_token(reviewer) }

        it 'returns a 200' do
          post :goodchat
          expect(response.status).to eq(200)
        end

        it 'returns a userId and displayName' do
          post :goodchat
          expect(parsed_body['userId']).to eq(reviewer.id)
          expect(parsed_body['displayName']).to eq(reviewer.first_name + ' ' + reviewer.last_name)
        end

        it 'grants the chat:customer permissions' do
          post :goodchat
          expect(parsed_body['permissions']).to eq(['chat:customer'])
        end
      end

      context 'as a supervisor' do
        before { generate_and_set_token(supervisor) }

        it 'returns a 200' do
          post :goodchat
          expect(response.status).to eq(200)
        end

        it 'returns a userId and displayName' do
          post :goodchat
          expect(parsed_body['userId']).to eq(supervisor.id)
          expect(parsed_body['displayName']).to eq(supervisor.first_name + ' ' + supervisor.last_name)
        end

        it 'grants the chat:customer and admin permissions' do
          post :goodchat
          expect(parsed_body['permissions']).to eq(['chat:customer', 'admin'])
        end
      end
      
      context 'as a non reviewer/supervisor staff member (e.g stock_management)' do
        before { generate_and_set_token(stock_manager) }

        it 'returns a 200' do
          post :goodchat
          expect(response.status).to eq(200)
        end

        it 'returns a userId and displayName' do
          post :goodchat
          expect(parsed_body['userId']).to eq(stock_manager.id)
          expect(parsed_body['displayName']).to eq(stock_manager.first_name + ' ' + stock_manager.last_name)
        end

        it 'does not grant permission to chat with customers' do
          post :goodchat
          expect(parsed_body['permissions']).to eq([])
        end
      end
    end
  end

  describe '#resend_pin' do
    let(:user) { create(:user, :with_token) }
    let(:mobile) { '+85290369036' }
    before { generate_and_set_token(user) }

    it 're-sends pin for logged in user' do
      post :resend_pin, params: { mobile: mobile }
      expect(response).to have_http_status(:success)
      expect(Token.new(bearer: response_json['otp_auth_key']).read('mobile')).to eq(mobile)
    end

    context 'when user is not logged in' do
      it 'raises unauthorised error' do
        request.headers['Authorization'] = nil
        post :resend_pin, params: { mobile: mobile }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when mobile is invalid' do
      it 'raises validation error' do
        post :resend_pin, params: { mobile: '90369036' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json['error']).to eq('Mobile is invalid')
      end
    end
  end
end
