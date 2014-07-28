module ModelMacros
  def before_n_after_otp_for_twilio_sms
    @valid_mobile_user = create :user_with_specifics
    @before_otp_code   = @valid_mobile_user.auth_tokens.recent_auth_token[:otp_code]
    @before_otp_expiry = @valid_mobile_user.token_expiry
    expect_any_instance_of(User).to receive(:update_otp){
    @valid_mobile_user.auth_tokens.recent_auth_token.update_columns(otp_code: 614979,
                                                                   otp_code_expiry: (Date.today + 11.hours));
    @valid_mobile_user.auth_tokens.recent_auth_token}
    VCR.use_cassette "sms_otp_code" do
      @token_key         = @valid_mobile_user.send_verification_pin(1.seconds)
    end
    @after_otp_code    = @valid_mobile_user.auth_tokens.recent_auth_token[:otp_code]
    @after_otp_expiry  = @valid_mobile_user.token_expiry
  end
end
