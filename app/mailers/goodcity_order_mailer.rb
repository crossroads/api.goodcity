# frozen_string_literal: true

# goodcity mailer for orders
class GoodcityOrderMailer < ApplicationMailer
  before_action :initialize_mailer_attributes
  before_action :configure_order_email_properties

  def send_appointment_confirmation_email
    params = create_params(subject: I18n.t('email.subject.appointment.confirmation', code: @order.code))
    mail(params)
  end

  def send_order_submission_pickup_email
    params = create_params(subject: I18n.t('email.subject.order.submission_pickup_delivery',
                                           code: @order.code, booking_type: booking_type))
    mail(params)
  end

  def send_order_submission_delivery_email
    params = create_params(subject: I18n.t('email.subject.order.submission_pickup_delivery',
                                           code: @order.code, booking_type: booking_type))
    mail(params)
  end

  def send_order_confirmation_pickup_email
    params = create_params(subject: I18n.t('email.subject.order.confirmation_pickup_delivery',
                                           code: @order.code, booking_type: booking_type))
    mail(params)
  end

  def send_order_confirmation_delivery_email
    params = create_params(subject: I18n.t('email.subject.order.confirmation_pickup_delivery',
                                           code: @order.code, booking_type: booking_type))
    mail(params)
  end

  private

  # Always use id here instead of passing ActiveRecord object as param,
  # since things will run under sidekiq
  def initialize_mailer_attributes
    @user  =  User.find_by(id: params[:user_id])
    @order =  Order.find_by(id: params[:order_id])
  end

  def configure_order_email_properties
    throw(:abort) unless @user.email.present?

    @email_property = @user.email_properties
                           .merge(@order.email_properties)
                           .with_indifferent_access
  end

  def create_params(subject:, user: @user)
    params = { to: user.email, subject: subject }
    params[:bcc] = ["#{I18n.t('email_from_name')} <#{ENV['BCC_EMAIL']}>"] if ENV['BCC_EMAIL'].present?
    params
  end

  def booking_type
    I18n.locale == 'en' ? @order.booking_type.name_en : @order.booking_type.name_zh_tw
  end
end
