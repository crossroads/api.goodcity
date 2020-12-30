# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/goodcity_mailer
# ** Example: **
#
# 1. To check the preview for "appointment_confirmation_email" email, define the method with some dummy attibutes
#
# def appointment_confirmation_email
#   order = Order.find(412)
#   GoodcityMailer.with(user_id: order.created_by_id, order_id: order.id).send_appointment_confirmation_email
# end
#
# 2. Visit http://localhost:3000/rails/mailers/goodcity_mailer/appointment_confirmation_email
class GoodcityMailerPreview < ActionMailer::Preview
end
