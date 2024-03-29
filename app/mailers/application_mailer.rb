# frozen_string_literal: true

# Base class to be inherited by all Mailer class
class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  SMTP_SERVER_ERRORS = [IOError,
                        Net::SMTPAuthenticationError,
                        Net::SMTPServerBusy,
                        Net::SMTPUnknownError,
                        Timeout::Error].freeze

  SMTP_CLIENT_ERRORS = [Net::SMTPFatalError, Net::SMTPSyntaxError].freeze

  SMTP_ERRORS = [SMTP_SERVER_ERRORS, SMTP_CLIENT_ERRORS].flatten

  rescue_from(*SMTP_ERRORS, with: :capture_smtp_errors)

  private

  def capture_smtp_errors(exception)
    Sentry.capture_exception(exception)
  end
end
