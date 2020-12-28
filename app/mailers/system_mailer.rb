# frozen_string_literal: true

# SystemMailer - to send system wide email
class SystemMailer < ApplicationMailer
  before_action :initialize_mailer_attributes
  before_action :configure_order_email_properties, only: %i[send_appointment_confirmation_email
                                                            send_order_submission_pickup_email
                                                            send_order_submission_delivery_email
                                                            send_order_confirmation_pickup_email
                                                            send_order_confirmation_delivery_email]

  def send_appointment_confirmation_email
    params = order_email_params(subject: I18n.t('email.appointment.confirmation', @order.code))
    mail(params)
  end

  def send_order_submission_pickup_email
    params = order_email_params(subject: I18n.t('email.order.submission_pickup', @order.code))
    mail(params)
  end

  def send_pin_email
    @pin = params[:pin]
    mail(to: 'bharat.h@kiprosh.com', subject: 'GoodCity.HK pin code')
  end

  private

  def configure_order_email_properties
    return false unless @user.email.present?

    @order_email_config = @user.email_properties.merge(@order.email_properties)
  end

  def initialize_mailer_attributes
    @user  =  params[:user]
    @order =  params[:order]
    @pin   =  params[:pin]
  end

  def order_email_params(user: @user, order: @order, subject:)
    params = { to: user.email, subject: subject }.merge(@order_email_config)
    params[:bcc] = ["#{I18n.t('email_from_name')} <#{ENV['BCC_EMAIL']}>"] if ENV['BCC_EMAIL'].present?
    mail(params)
  end
end
