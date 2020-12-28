# frozen_string_literal: true

# Base class to be inherited by all Mailer class
class ApplicationMailer < ActionMailer::Base
  before_action :restrict_mail_ability
  # TODO: get the correct from email address
  default from: "#{I18n.t('email_from_name')} <notifications@example.com>"
  layout 'mailer'

  SMTP_SERVER_ERRORS = [IOError,
                        Net::SMTPAuthenticationError,
                        Net::SMTPServerBusy,
                        Net::SMTPUnknownError,
                        Timeout::Error].freeze

  SMTP_CLIENT_ERRORS = [Net::SMTPFatalError, Net::SMTPSyntaxError].freeze

  SMTP_ERRORS = [SMTP_SERVER_ERRORS, SMTP_CLIENT_ERRORS].flatten

  # TODO: Create an exception class for it
  # Perform any exception logging
  rescue_from *SMTP_ERRORS do |exception|
    Rollbar.warning(exception)
  end

  def restrict_mail_ability
    return false unless Rails.env.production? || Rails.env.staging?
  end
end
