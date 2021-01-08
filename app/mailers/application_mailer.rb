# frozen_string_literal: true

# Base class to be inherited by all Mailer class
class ApplicationMailer < ActionMailer::Base
  default from: 'GoodCity <contact@goodcity.hk>'
  layout 'mailer'

  SMTP_SERVER_ERRORS = [IOError,
                        Net::SMTPAuthenticationError,
                        Net::SMTPServerBusy,
                        Net::SMTPUnknownError,
                        Timeout::Error].freeze

  SMTP_CLIENT_ERRORS = [Net::SMTPFatalError, Net::SMTPSyntaxError].freeze

  SMTP_ERRORS = [SMTP_SERVER_ERRORS, SMTP_CLIENT_ERRORS].flatten

  rescue_from(*SMTP_ERRORS, with: :capture_smtp_errors)

  before_action :initialize_mailer_attributes

  # Log Rollbar warning for any errors
  def capture_smtp_errors(exception)
    Rollbar.warning(exception)
  end

  # Always use id here instead of passing ActiveRecord object as param,
  # since things will run under sidekiq
  def initialize_mailer_attributes
    @user  =  User.find_by(id: params[:user_id])
    @order =  Order.find_by(id: params[:order_id])
  end
end
