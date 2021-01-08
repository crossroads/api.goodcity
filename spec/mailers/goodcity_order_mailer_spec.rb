require 'rails_helper'

RSpec.describe GoodcityOrderMailer, type: :mailer do
  describe 'Order emails' do
    let(:user) { create(:user, :charity) }
    let(:order) { create(:order, created_by: user) }

    describe 'send_appointment_confirmation_email' do
      let(:mailer) { GoodcityOrderMailer.with(user_id: user.id, order_id: order.id).send_appointment_confirmation_email }

      it 'sets proper to and subject' do
        expect(mailer.subject).to eq(I18n.t('email.subject.appointment.confirmation', code: order.code))
        expect(mailer.to[0]).to eq(user.email)
      end

      it 'sets proper params' do
        expect(mailer['contact-name'].value).to eq("#{user.first_name} #{user.last_name}")
        expect(mailer['contact-organisation-name-en'].value).to eq(user.organisations.first.name_en)
      end

      context 'when there are no beneficiary' do
        it 'does not have client details in params' do
          order.update(beneficiary: nil)
          expect(mailer['client']).to be_nil
        end
      end

      context 'when there is a beneficiary' do
        let(:order) { create(:order, created_by: user, beneficiary: create(:beneficiary)) }

        it 'has client details in the params' do
          expect(mailer['client']).not_to be_nil
        end

        it 'has client name, phone and id_type details' do
          values = eval(mailer['client'].value)
          expect(values['name']).to eq("#{order.beneficiary.first_name} #{order.beneficiary.last_name}")
          expect(values['phone']).to eq(order.beneficiary.phone_number)
          expect(values['id_type']).to eq(order.beneficiary.identity_type.name_en)
          expect(values['id_no']).to eq(order.beneficiary.identity_number)
        end
      end

      context 'when order has goodcity requests' do
        let(:order) { create(:order, :with_goodcity_requests, created_by: user) }

        it 'has requests present in the params' do
          expect(mailer['requests']).not_to be_nil
        end

        it 'has quantity, type and description' do
          values = eval(mailer['requests'].value)
          expect(values['quantity']).to eq(order.goodcity_requests.count)
          expect(values['type_en']).to eq(order.goodcity_requests.first.package_type.name_en)
          expect(values['description']).to eq(order.goodcity_requests.first.description)
        end
      end
    end

    describe 'send_order_submission_pickup_email' do
      let(:mailer) { GoodcityMailer.with(user_id: user.id, order_id: order.id).send_order_submission_pickup_email }

      %w[en zh-tw].each do |locale|
        it "sets proper subject according to the locale #{locale}" do
          I18n.locale = locale
          expect(mailer.subject).to eq(I18n.t('email.subject.order.submission_pickup_delivery', code: order.code, booking_type: order.booking_type.name_en))
        end
      end

      it 'sets contact_name in param' do
        expect(mailer['contact-name'].value).to eq("#{user.first_name} #{user.last_name}")
      end

      it 'sets proper booking_type params' do
        expect(mailer['booking-type'].value).to eq(order.booking_type.name_en)
      end

      it 'sets proper domain in params' do
        expect(mailer['domain'].value).to eq('browse')
      end
    end

    describe 'send_order_submission_delivery_email' do
      let(:mailer) { GoodcityMailer.with(user_id: user.id, order_id: order.id).send_order_submission_delivery_email }

      %w[en zh-tw].each do |locale|
        it "sets proper subject according to the locale #{locale}" do
          I18n.locale = locale
          expect(mailer.subject).to eq(I18n.t('email.subject.order.submission_pickup_delivery', code: order.code, booking_type: order.booking_type.name_en))
        end
      end

      it 'sets proper contact_name in params' do
        expect(mailer['contact-name'].value).to eq("#{user.first_name} #{user.last_name}")
      end

      it 'sets proper booking_type params' do
        expect(mailer['booking-type'].value).to eq(order.booking_type.name_en)
      end

      it 'sets proper domain in params' do
        expect(mailer['domain'].value).to eq('browse')
      end
    end

    describe 'send_order_confirmation_pickup_email' do
      let(:mailer) { GoodcityMailer.with(user_id: user.id, order_id: order.id).send_order_confirmation_pickup_email }

      it 'sets proper to and subject' do
        expect(mailer.subject).to eq(I18n.t('email.subject.order.confirmation_pickup_delivery', code: order.code))
        expect(mailer.to[0]).to eq(user.email)
      end

      it 'sets proper contact params' do
        expect(mailer['contact-name'].value).to eq("#{user.first_name} #{user.last_name}")
        expect(mailer['contact-organisation-name-en'].value).to eq(user.organisations.first.name_en)
      end

      it 'sets proper order_code params' do
        expect(mailer['order-code'].value).to eq(order.code)
      end

      context 'when there are no beneficiary' do
        it 'does not have client details in params' do
          order.update(beneficiary: nil)
          expect(mailer['client']).to be_nil
        end
      end

      context 'when there is a beneficiary' do
        let(:order) { create(:order, created_by: user, beneficiary: create(:beneficiary)) }

        it 'has client details in the params' do
          expect(mailer['client']).not_to be_nil
        end

        it 'has client name, phone and id_type details' do
          values = eval(mailer['client'].value)
          expect(values['name']).to eq("#{order.beneficiary.first_name} #{order.beneficiary.last_name}")
          expect(values['phone']).to eq(order.beneficiary.phone_number)
          expect(values['id_type']).to eq(order.beneficiary.identity_type.name_en)
          expect(values['id_no']).to eq(order.beneficiary.identity_number)
        end
      end

      context 'when order has goodcity requests' do
        let(:order) { create(:order, :with_goodcity_requests, created_by: user) }

        it 'has requests present in the params' do
          expect(mailer['requests']).not_to be_nil
        end

        it 'has quantity, type and description' do
          values = eval(mailer['requests'].value)
          expect(values['quantity']).to eq(order.goodcity_requests.count)
          expect(values['type_en']).to eq(order.goodcity_requests.first.package_type.name_en)
          expect(values['description']).to eq(order.goodcity_requests.first.description)
        end
      end
    end

    describe 'send_order_confirmation_delivery_email' do
      let(:order) { create(:order, created_by: user, order_transport: create(:order_transport)) }
      let(:mailer) { GoodcityMailer.with(user_id: user.id, order_id: order.id).send_order_confirmation_delivery_email }

      it 'sets proper to and subject' do
        expect(mailer.subject).to eq(I18n.t('email.subject.order.confirmation_pickup_delivery', code: order.code))
        expect(mailer.to[0]).to eq(user.email)
      end

      it 'sets proper contact params' do
        expect(mailer['contact-name'].value).to eq("#{user.first_name} #{user.last_name}")
        expect(mailer['contact-organisation-name-en'].value).to eq(user.organisations.first.name_en)
      end

      it 'sets proper order_code params' do
        expect(mailer['order-code'].value).to eq(order.code)
      end

      it 'sets proper scheduled_at params' do
        expect(mailer['scheduled_at'].value).to eq(order.order_transport.scheduled_at.in_time_zone.strftime('%e %b %Y %H:%M%p'))
      end

      context 'if order has beneficiary' do
        let(:order) { create(:order, created_by: user, beneficiary: create(:beneficiary)) }

        it 'has client details in the params' do
          expect(mailer['client']).not_to be_nil
        end

        it 'has client name, phone and id_type details' do
          values = eval(mailer['client'].value)
          expect(values['name']).to eq("#{order.beneficiary.first_name} #{order.beneficiary.last_name}")
          expect(values['phone']).to eq(order.beneficiary.phone_number)
          expect(values['id_type']).to eq(order.beneficiary.identity_type.name_en)
          expect(values['id_no']).to eq(order.beneficiary.identity_number)
        end
      end

      context 'if order has no beneficiary' do
        it 'has empty client params' do
          order.update(beneficiary: nil)
          expect(mailer['client']).to be_nil
        end
      end
    end
  end
end
