# config/initializers/dynamic_smtp_interceptor.rb
#
# Interceptor that changes the SMTP settings when certain domains are matched.
#
# Requires the following ENV VARs to be set:
#   ACS_SMTP_ADDRESS
#   ACS_SMTP_PORT
#   ACS_SMTP_DOMAIN
#   ACS_SMTP_AUTHENTICATION
#   ACS_SMTP_ENABLE_STARTTLS_AUTO
#   ACS_SMTP_USERNAME
#   ACS_SMTP_PASSWORD
#   ACS_SMTP_FROM_EMAIL
#   ACS_SMTP_DOMAINS_TO_REDIRECT # (comma-separated list of domains)

class DynamicACSSmtpInterceptor

  def self.delivering_email(message)
    if settings_active? and redirect_to_acs_smtp?(message)
      # ACS requries From to be a specific email address.
      message.reply_to = message.from
      message.from = ENV['ACS_SMTP_FROM_EMAIL']
      # This sets the delivery method for this single Mail::Message instance.
      message.delivery_method(:smtp, acs_smtp_settings)
    end
  end

  # Criteria for changing SMTP settings:
  #   - any recipient to, cc, bcc email address that ends with a particular domain
  def self.redirect_to_acs_smtp?(message)
    recipients = Array(message.to) + Array(message.cc) + Array(message.bcc)
    recipient_domains = recipients.map{|r| r.split('@').last}.uniq.compact
    (Set.new(recipient_domains) & Set.new(domains_to_redirect)).any?
  end

  # Comma separated list of domains to redirect
  #   E.g. gmail.com,yahoo.com
  def self.domains_to_redirect
    (ENV['ACS_SMTP_DOMAINS_TO_REDIRECT'] || '').split(',').map(&:strip)
  end

  def self.acs_smtp_settings
    {
      address: ENV['ACS_SMTP_ADDRESS'],
      port: ENV['ACS_SMTP_PORT'].to_i,
      domain: ENV['ACS_SMTP_DOMAIN'],
      user_name: ENV['ACS_SMTP_USERNAME'],
      password: ENV['ACS_SMTP_PASSWORD'],
      authentication: ENV['ACS_SMTP_AUTHENTICATION'],
      enable_starttls_auto: (ENV['ACS_SMTP_ENABLE_STARTTLS_AUTO'].to_s == 'true')
    }
  end

  # Comment out ENV vars to disable this interceptor.
  def self.settings_active?
    return self.acs_smtp_settings[:address].present? &&
      self.acs_smtp_settings[:port].present? &&
      self.acs_smtp_settings[:domain].present? &&
      self.acs_smtp_settings[:user_name].present? &&
      self.acs_smtp_settings[:password].present? &&
      self.acs_smtp_settings[:authentication].present? &&
      self.acs_smtp_settings[:enable_starttls_auto].present?
  end

end

# Register the interceptor so it's invoked for every outgoing email.
ActionMailer::Base.register_interceptor(DynamicACSSmtpInterceptor)