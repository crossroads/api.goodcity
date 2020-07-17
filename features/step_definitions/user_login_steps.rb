# frozen_string_literal: true

Given(/^I am a ([supervisor | reviewer]+) logging into "([^"]*)" app/) do |name, app|
  @user = create(:user, :with_multiple_roles_and_permissions, roles_and_permissions: { name.humanize => ['can_login_to_admin'] })
  header 'X-GOODCITY-APP-NAME', "#{app}.goodcity"
end

Given(/^I am a ([order_administrator | order_fulfilment]+) logging into "([^"]*)" app/) do |name, app|
  @user = create(:user, :with_multiple_roles_and_permissions, roles_and_permissions: { name.humanize => ['can_login_to_stock'] })
  header 'X-GOODCITY-APP-NAME', "#{app}.goodcity"
end

And('I enter the mobile number') do
  request('api/v1/auth/send_pin', method: :post, params: { mobile: @user.mobile })
  @response = last_response
end

And('I enter the pin') do
  otp = @user.most_recent_token.otp_code
  otp_auth_key = parsed_body['otp_auth_key']
  request('api/v1/auth/verify', method: :post, params: { otp_auth_key: otp_auth_key, pin: otp })
  @response = last_response
end

Then('I should not be allowed to login') do
  expect(@response.status).to eq(401)
end

Then('I should be allowed to login') do
  expect(@response.status).to eq(200)
end
