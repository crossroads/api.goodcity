# frozen_string_literal: true

# GoodcityMailer - to send system wide email
class GoodcityMailer < ApplicationMailer
  ORDER_RELATED_EMAILS = %i[send_appointment_confirmation_email send_order_submission_pickup_email
                            send_order_submission_delivery_email send_order_confirmation_pickup_email
                            send_order_confirmation_delivery_email].freeze

  before_action :initialize_mailer_attributes
  before_action :configure_order_email_properties, only: ORDER_RELATED_EMAILS

  def send_appointment_confirmation_email
    @params = create_order_email_params(subject: I18n.t('email.subject.appointment.confirmation', code: @order.code))
    mail(@params)
  end

  def send_order_submission_pickup_email
    @params = create_order_email_params(subject: I18n.t('email.subject.order.submission_pickup_delivery',
                                                        code: @order.code, booking_type: booking_type))
    mail(@params)
  end

  def send_order_submission_delivery_email
    @params = create_order_email_params(subject: I18n.t('email.subject.order.submission_pickup_delivery',
                                                        code: @order.code, booking_type: booking_type))
    mail(params)
  end

  def send_order_confirmation_pickup_email
    @params = create_order_email_params(subject: I18n.t('email.subject.order.submission_pickup_delivery',
                                                        code: @order.code, booking_type: booking_type))
    mail(params)
  end

  def send_order_confirmation_delivery_email
    @params = create_order_email_params(subject: I18n.t('email.subject.order.confirmation_pickup_delivery',
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

  # Always use id here instead of passing ActiveRecord object as param,
  # since things will run under sidekiq
  def initialize_mailer_attributes
    @user  =  User.find(params[:user_id])
    @order =  Order.find(params[:order_id])
  end

  def create_order_email_params(subject:, user: @user)
    params = { to: user.email, subject: subject }.merge(@order_email_config)
    params[:bcc] = ["#{I18n.t('email_from_name')} <#{ENV['BCC_EMAIL']}>"] if ENV['BCC_EMAIL'].present?
    params.with_indifferent_access
  end

  def booking_type
    I18n.locale == 'en' ? @order.booking_type.name_en : @order.booking_type.name_zh_tw
  end
end
