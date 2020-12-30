# frozen_string_literal: true

# Base class to be inherited by all Mailer class
class ApplicationMailer < ActionMailer::Base
  include ActiveSupport::Rescuable
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

  rescue_from(*SMTP_ERRORS, with: :capture_smptp_errors)

  # Log Rollbar warning for any errors
  def capture_smptp_errors(exception)
    Rollbar.warning(exception)
  end
end
