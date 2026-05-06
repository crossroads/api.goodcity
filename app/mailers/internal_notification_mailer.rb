# frozen_string_literal: true

# Simple internal emails (Rails 8+ no longer supports ActionMailer::Base.mail).
class InternalNotificationMailer < ApplicationMailer
  default from: -> { ENV.fetch("EMAIL_FROM") }

  def plain(to:, subject:, body:)
    mail(to: to, subject: subject, body: body)
  end
end
