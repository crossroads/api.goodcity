#
# create(:auth_token) - does NOT associate with a user
# create(:user_with_auth_token) - correct way to generate a user with auth_token
#
FactoryBot.define do
  factory :auth_token do
    otp_code_expiry { Time.now + Rails.application.secrets.token['otp_code_validity'] }
  end
end
