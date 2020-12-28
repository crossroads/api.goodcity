# frozen_string_literal: true

# SystemMailer - to send system wide email
class SystemMailer < ApplicationMailer
  ORDER_RELATED_EMAILS = %i[send_appointment_confirmation_email send_order_submission_pickup_email
                            send_order_submission_delivery_email send_order_confirmation_pickup_email
                            send_order_confirmation_delivery_email].freeze

  before_action :initialize_mailer_attributes
  before_action :configure_order_email_properties, only: ORDER_RELATED_EMAILS

  def send_appointment_confirmation_email
    params = create_order_email_params(subject: I18n.t('email.subject.appointment.confirmation', code: @order.code))
    mail(params)
  end

  def send_order_submission_pickup_email
    params = create_order_email_params(subject: I18n.t('email.subject.order.submission_pickup', code: @order.code))
    mail(params)
  end

  def send_order_submission_delivery_email
    booking_type = I18n.locale == 'en' ? @order.booking_type.name_en : @order.booking_type.name_zh_tw
    params = create_order_email_params(subject: I18n.t('email.subject.order.submission_delivery',
                                                       code: @order.code, booking_type: booking_type))
    mail(params)
  end

  def send_order_confirmation_pickup_email
    params = create_order_email_params(subject: I18n.t('email.subject.order.confirmation_pickup',
                                                       code: @order.code))
    mail(params)
  end

  def send_order_confirmation_delivery_email
    booking_type = I18n.locale == 'en' ? @order.booking_type.name_en : @order.booking_type.name_zh_tw
    params = create_order_email_params(subject: I18n.t('email.subject.order.confirmation_delivery',
                                                       code: @order.code, booking_type: booking_type))
    mail(params)
  end

  def send_pin_email
    @pin = params[:pin]
    mail(to: @user.email, subject: I18n.t('email.subject.login'))
  end

  private

  def configure_order_email_properties
    throw(:abort) unless @user.email.present?

    @order_email_config = @user.email_properties.merge(@order.email_properties)
  end

  # TODO: Use id here, since things will un under sidekiq
  def initialize_mailer_attributes
    @user  =  params[:user]
    @order =  params[:order]
    @pin   =  params[:pin]
  end

  def create_order_email_params(subject:, user: @user)
    params = { to: user.email, subject: subject }.merge(@order_email_config)
    params[:bcc] = ["#{I18n.t('email_from_name')} <#{ENV['BCC_EMAIL']}>"] if ENV['BCC_EMAIL'].present?
    params
  end
end
