require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe "ApplicationController" do
    #------------------------------------------------------------------------
    let!(:user) {create(:user_with_specifics)}
    let!(:pin) {user.auth_tokens.recent_auth_token[:otp_code]}
    let!(:token) {user.auth_tokens.recent_auth_token[:otp_secret_key]}

    let!(:jwt_token) {
      controller.send(:generate_enc_session_token,user.mobile,token)}

    let!(:set_jwt_auth_header){
      request.env['HTTP_AUTHORIZATION'] = "Bearer #{jwt_token}" }

    let!(:authorized_jwt_token){
      set_jwt_auth_header.try(:sub, "Bearer","").try(:split, ' ').try(:last) }
    #------------------------------------------------------------------------

    context "set_locale" do
      it "should set locale to zh-tw" do
        set_locale('zh-tw')
        controller.send(:set_locale)
        expect(I18n.locale).to eql(:'zh-tw')
      end

      it "should set locale to en" do
        set_locale('en', 'zh-tw')
        controller.send(:set_locale)
        expect(I18n.locale).to eql(:en)
      end
    end

    context 'token header' do
      it 'has validate authorization header set' do
        request.headers['Authorization'] = "Bearer  s2xtqb5mspzg4rq7"
        expect(controller.send(:token_header)).to eq("s2xtqb5mspzg4rq7")
      end
      it 'had empty authorization header' do
        request.headers['Authorization'] = "Bearer   "
        expect(controller.send(:token_header)).to eq("undefined")
      end
    end

    context 'verify warden' do
      it 'warden object' do
        expect(controller.send(:warden)).to eq(request.env["warden"])
      end

      it 'env[warden_options] object' do
        expect(controller.send(:warden_options)).to eq(request.env["warden_options"])
      end
    end

    context 'validate JWT token' do
      it 'should be present' do
        login_as(user)
        expect(controller.send(:token_header)).not_to be_blank
      end

      it 'should be decoded by encoding key' do
        login_as(user)
        cur_time = Time.now.to_i
        token_header_value = controller.send(:token_header)
        jwt_decoded_json = controller.send(:decode_session_token, token_header_value)

        expect(jwt_decoded_json["iat"]).to be <= cur_time
        expect(jwt_decoded_json["iss"]).to eq(Rails.application.secrets.jwt['issuer'])
        expect(jwt_decoded_json["exp"]).to be > cur_time
        expect(jwt_decoded_json["mobile"]).to eq(user.mobile)
        expect(jwt_decoded_json["otp_secret_key"]).to eq(user.friendly_token)
      end

      it 'should not be decoded by encoding key' do
        login_as(user)
        token_header_value = controller.send(:token_header).sub("e","x")
        expect{controller.send(:decode_session_token, token_header_value)}.to raise_error(Module::DelegationError)
      end

      it 'should be authenitic token' do
        login_as(user)
        token_header_value = controller.send(:token_header)
        jwt_decoded_json = controller.send(:decode_session_token, token_header_value)
        expect((controller.send(:validate_authenticity_of_jwt,
          jwt_decoded_json))[:message]).to eq(I18n.t('warden.token_valid'))
      end

      it 'should be valid authenitic token' do
        login_as(user)
        expect((controller.send(:validate_token))[:message]).to eq(I18n.t('warden.token_valid'))
      end

    end
  end
end
