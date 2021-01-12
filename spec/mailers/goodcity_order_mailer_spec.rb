require 'rails_helper'


RSpec.describe GoodcityOrderMailer, type: :mailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe 'Order emails' do
    let(:user) { create(:user, :charity) }
    let(:order) { create(:order, created_by: user) }
    subject(:subject) { described_class.with(user_id: user.id, order_id: order.id) }

    before(:each) do
      I18n.locale = 'en'
    end

    describe 'send_appointment_confirmation_email' do
      let(:mailer) { subject.send_appointment_confirmation_email }

      it 'sets proper to and subject' do
        expect(mailer).to have_subject(I18n.t('email.subject.appointment.confirmation', code: order.code))
        expect(mailer).to deliver_to(user.email)
      end

      it 'sets proper params' do
        expect(mailer).to have_body_text("#{user.first_name} #{user.last_name}")
        expect(mailer).to have_body_text(user.organisations.first.name_en)
      end

      context 'when there are no beneficiary' do
        it 'does not have client details in params' do
          order.update(beneficiary: nil)
          expect(mailer).not_to have_body_text(/Client Name:/)
        end
      end

      context 'when there is a beneficiary' do
        let(:order) { create(:order, created_by: user, beneficiary: create(:beneficiary)) }

        it 'has client name, phone and id_type details' do
          name = "#{order.beneficiary.first_name} #{order.beneficiary.last_name}"
          expect(mailer).to have_body_text("<b>Client Name:</b> #{name}")

          expect(mailer).to have_body_text("<b>Client contact:</b> #{order.beneficiary.phone_number}")
          expect(mailer).to have_body_text("*** #{order.beneficiary.identity_number}(*)")
        end
      end

      context 'when order has goodcity requests' do
        let(:order) { create(:order, :with_goodcity_requests, created_by: user) }

        it 'has quantity, type and description' do
          quantity = order.goodcity_requests.count
          type_en = order.goodcity_requests.first.package_type.name_en
          description = order.goodcity_requests.first.description
          expect(mailer).to have_body_text("#{quantity} x #{type_en}. #{description}.")
        end
      end
    end

    describe 'send_order_submission_pickup_email' do
      let(:mailer) { subject.send_order_submission_pickup_email }

      %w[en zh-tw].each do |locale|
        it "sets proper subject according to the locale #{locale}" do
          I18n.locale = locale
          expect(mailer).to have_subject(I18n.t('email.subject.order.submission_pickup_delivery', code: order.code, booking_type: order.booking_type.name_en))
        end
      end

      it 'sets contact_name' do
        expect(mailer).to have_body_text("Dear #{user.first_name} #{user.last_name}")
      end

      it 'sets proper booking_type and order_code' do
        expect(mailer).to have_body_text("Thank you for submitting #{order.booking_type.name_en} #{order.code}")
      end
    end

    describe 'send_order_submission_delivery_email' do
      let(:mailer) { subject.send_order_submission_delivery_email }

      %w[en zh-tw].each do |locale|
        it "sets proper subject according to the locale #{locale}" do
          I18n.locale = locale
          expect(mailer).to have_subject(I18n.t('email.subject.order.submission_pickup_delivery', code: order.code, booking_type: order.booking_type.name_en))
        end
      end

      it 'sets proper contact_name' do
        expect(mailer).to have_body_text("Dear #{user.first_name} #{user.last_name}")
      end

      it 'sets proper booking_type' do
        expect(mailer).to have_body_text("Thank you for submitting order #{order.code}")
      end
    end

    describe 'send_order_confirmation_pickup_email' do
      let(:mailer) { subject.send_order_confirmation_pickup_email }
      let(:order) { create(:order, :with_goodcity_requests, created_by: user, order_transport: create(:order_transport)) }

      it 'sets proper to and subject' do
        expect(mailer).to have_subject(I18n.t('email.subject.order.confirmation_pickup_delivery', code: order.code))
        expect(mailer).to deliver_to(user.email)
      end

      it 'sets proper contact fields' do
        expect(mailer).to have_body_text("<strong>Attention:</strong> #{user.first_name} #{user.last_name}")
        expect(mailer).to have_body_text(user.organisations.first.name_en)
      end

      it 'sets proper order_code' do
        expect(mailer).to have_body_text("<strong>Our Ref#: </strong> #{order.code}")
      end

      it 'sets proper scheduled_at' do
        time = order.order_transport.scheduled_at.in_time_zone.strftime('%e %b %Y %H:%M%p')
        expect(mailer).to have_body_text("goods can be collected on the #{time}")
      end

      context 'when there are no beneficiary' do
        it 'does not have client details in params' do
          order.update(beneficiary: nil)
          expect(mailer).not_to have_body_text('Client Name: ')
        end
      end

      context 'when there is a beneficiary' do
        let(:order) { create(:order, created_by: user, beneficiary: create(:beneficiary)) }

        it 'has client name, phone and id_type details' do
          name = "#{order.beneficiary.first_name} #{order.beneficiary.last_name}"
          expect(mailer).to have_body_text("<strong>Client Name: </strong>#{name}")

          expect(mailer).to have_body_text("<strong>Client contact: </strong> #{order.beneficiary.phone_number}")
          expect(mailer).to have_body_text("***#{order.beneficiary.identity_number}(*)")
        end
      end

      context 'when order has goodcity requests' do
        let(:order) { create(:order, :with_goodcity_requests, created_by: user) }

        it 'has quantity, type and description' do
          quantity = order.goodcity_requests.count
          type_en = order.goodcity_requests.first.package_type.name_en
          description = order.goodcity_requests.first.description
          expect(mailer).to have_body_text("#{quantity} x #{type_en}. #{description}.")
        end
      end
    end

    describe 'send_order_confirmation_delivery_email' do
      let(:order) { create(:order, created_by: user, order_transport: create(:order_transport)) }
      let(:mailer) { subject.send_order_confirmation_delivery_email }

      it 'sets proper to and subject' do
        expect(mailer).to have_subject(I18n.t('email.subject.order.confirmation_pickup_delivery', code: order.code))
        expect(mailer).to deliver_to(user.email)
      end

      it 'sets proper contact params' do
        expect(mailer).to have_body_text("<b>Attention: </b> #{user.first_name} #{user.last_name}")
        expect(mailer).to have_body_text(user.organisations.first.name_en)
      end

      it 'sets proper order_code params' do
        expect(mailer).to have_body_text("<b>Our Ref#:</b> #{order.code}")
      end

      it 'sets proper scheduled_at params' do
        time = order.order_transport.scheduled_at.in_time_zone.strftime('%e %b %Y %H:%M%p')
        expect(mailer).to have_body_text("to be delivered on #{time}")
      end

      context 'if order has beneficiary' do
        let(:order) { create(:order, created_by: user, beneficiary: create(:beneficiary)) }

        it 'addresses the beneficiary' do
          expect(mailer).to have_body_text('Our staff will call your beneficiary just before ordering the van to re-confirm that everything is in place for receiving the goods.')
        end
      end

      context 'if order has no beneficiary' do
        it 'does not addresses the beneficiary' do
          order.update(beneficiary: nil)
          expect(mailer).not_to have_body_text('Our staff will call your beneficiary just before ordering the van to re-confirm that everything is in place for receiving the goods.')
        end
      end
    end
  end
end
