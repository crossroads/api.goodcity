# frozen_string_literal: true

# Mailable concern
module Mailable
  extend ActiveSupport::Concern

  def send_pin_email(user)
    pin = user.most_recent_token.otp_code
    SystemMailer.with(pin: pin).send_pin_email.deliver_later
  end
end
