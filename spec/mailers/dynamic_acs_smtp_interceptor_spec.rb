require 'rails_helper'

RSpec.describe DynamicACSSmtpInterceptor do
  let(:message) { Mail.new(to: 'test@example.com', from: 'sender@example.com') }

  before(:each) do
    ENV['ACS_SMTP_ADDRESS'] = 'smtp.example.com'
    ENV['ACS_SMTP_PORT'] = '587'
    ENV['ACS_SMTP_DOMAIN'] = 'email.example.com'
    ENV['ACS_SMTP_AUTHENTICATION'] = 'login'
    ENV['ACS_SMTP_ENABLE_STARTTLS_AUTO'] = 'true'
    ENV['ACS_SMTP_USERNAME'] = 'smtp-dynamic-user'
    ENV['ACS_SMTP_PASSWORD'] = 'test-password'
    ENV['ACS_SMTP_FROM_EMAIL'] = 'DoNotReply@email.example.com'
    ENV['ACS_SMTP_DOMAINS_TO_REDIRECT'] = 'example.org,example.co.uk'
  end

  describe '.delivering_email' do
    it 'sets reply_to and from when conditions are met' do
      message.to = 'user@example.org'
      from = message.from
      DynamicACSSmtpInterceptor.delivering_email(message)
      expect(message.from).to eq([ ENV['ACS_SMTP_FROM_EMAIL'] ])
      expect(message.reply_to).to eq(from)
      expect(message.delivery_method.settings[:address]).to eql(ENV['ACS_SMTP_ADDRESS'])
    end

    it 'sets reply_to and from when conditions are met and sent to more than one user' do
      message.to = ['test@example.com', 'user@example.org']
      from = message.from
      DynamicACSSmtpInterceptor.delivering_email(message)
      expect(message.from).to eq([ ENV['ACS_SMTP_FROM_EMAIL'] ])
      expect(message.reply_to).to eq(from)
      expect(message.delivery_method.settings[:address]).to eql(ENV['ACS_SMTP_ADDRESS'])
    end

    it 'does not change delivery method when no recipients match the trigger domains' do
      message.to = ['test@example.com', 'user@example.net']
      DynamicACSSmtpInterceptor.delivering_email(message)
      expect(message.from).to eq([ 'sender@example.com' ])
      expect(message.reply_to).to eq(nil)
      expect(message.delivery_method.settings[:address]).not_to eql(ENV['ACS_SMTP_ADDRESS'])
    end
  end

  describe '.redirect_to_acs_smtp?' do
    describe 'returns true' do
      it 'if any recipients in "to" field match the redirect domains' do
        message.to = 'user@example.org' # matches
        message.cc = 'user@example.com' # doesn't match
        message.bcc = 'user@example.net' # doesn't match
        expect(DynamicACSSmtpInterceptor.redirect_to_acs_smtp?(message)).to be true
      end
      it 'if any recipients in "cc" field match the redirect domains' do
        message.to = 'user@example.com' # doesn't match
        message.cc = 'user@example.org' # matches
        message.bcc = 'user@example.net' # doesn't match
        expect(DynamicACSSmtpInterceptor.redirect_to_acs_smtp?(message)).to be true
      end
      it 'if any recipients in "bcc" field match the redirect domains' do
        message.to = 'user@example.net' # doesn't match
        message.cc = 'user@example.com' # doesn't match
        message.bcc = 'user@example.org' # matches
        expect(DynamicACSSmtpInterceptor.redirect_to_acs_smtp?(message)).to be true
      end
      it 'if multiple recipients match the redirect domains' do
        message.to = ['user@example.org', 'user1@example.com'] # matches
        message.cc = ['user2@example.com', 'user3@example.com'] # doesn't match
        message.bcc = ['user4@example.com', 'user5@example.com'] # doesn't match
        expect(DynamicACSSmtpInterceptor.redirect_to_acs_smtp?(message)).to be true
      end
    end

    it 'returns false if no recipients in matching domains' do
      message.to = 'user@example.com'
      message.cc = 'user@example.net'
      expect(DynamicACSSmtpInterceptor.redirect_to_acs_smtp?(message)).to be false
    end

    it 'returns true if at least one recipient matches' do
      message.to = ['user1@example.com', 'user2@example.co.uk']
      expect(DynamicACSSmtpInterceptor.redirect_to_acs_smtp?(message)).to be true
    end
    
  end

  describe '.domains_to_redirect' do
    it 'returns array of domains from ENV variable' do
      expect(DynamicACSSmtpInterceptor.domains_to_redirect).to eq(['example.org', 'example.co.uk'])
    end
    it 'returns empty array if ENV variable is not set' do
      ENV['ACS_SMTP_DOMAINS_TO_REDIRECT'] = nil
      expect(DynamicACSSmtpInterceptor.domains_to_redirect).to eq([])
    end
  end

  describe '.settings_active?' do
    it 'returns true when all ACS_SMTP_* settings are set' do
      expect(DynamicACSSmtpInterceptor.settings_active?).to be true
    end

    it 'returns false when ACS_SMTP_ADDRESS is not set' do
      ENV['ACS_SMTP_ADDRESS'] = nil
      expect(DynamicACSSmtpInterceptor.settings_active?).to be false
    end
  end
end