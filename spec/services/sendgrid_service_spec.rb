require "rails_helper"

describe SendgridService do
  let(:user) { build :user }
  let(:sendgrid) { SendgridService.new(user) }

  context "initialize" do
    it do
      expect(sendgrid.user).to equal(user)
    end
    it "without arguments" do
      expect { SendgridService.new }.to raise_error(ArgumentError)
    end
  end

  context "Template ID selection" do
    it "returns english template constant name if locale is en" do
      I18n.locale = :en
      expect(sendgrid.pin_template_id).to eq "SENDGRID_PIN_TEMPLATE_ID_EN"
    end

    it "returns chinese template constant name if locale is zh-tw" do
      I18n.locale = :"zh-tw"
      expect(sendgrid.pin_template_id).to eq "SENDGRID_PIN_TEMPLATE_ID_ZH_TW"
    end
  end

  describe "SMS Verification pin" do
    let(:otp_code) { "123456" }
    context "based on app_name" do
      before(:each) do
        allow(sendgrid).to receive(:send_to_sendgrid).and_return(true)
        allow(user).to receive_message_chain(:most_recent_token, :otp_code).and_return(otp_code)
        allow(sendgrid).to receive(:send_pin_email).and_return({status: 202})
        expect(sendgrid).to receive(:send_pin_email)
      end

      it "sends email" do
        sendgrid.send_pin_email
      end
    end
  end

  describe "Appointment confirmation email" do
    let!(:order) { create :order, :with_state_submitted }
    let!(:order_transport) { create :order_transport, order: order }
    let!(:beneficiary) { create :beneficiary, order: order }
    let(:organisation) { create :organisation }

    before(:each) do
      allow(sendgrid).to receive(:send_to_sendgrid).and_return(true)
      allow(sendgrid).to receive(:send_email).and_return(true)
    end

    context "Template data" do

      it "should send the user's information" do
        user.organisations = [organisation]
        user.save
        expect(sendgrid).to receive(:send_email) do
          data_sent = sendgrid.substitution_hash
          expect(data_sent['contact_name']).to eq(user.first_name + ' ' + user.last_name)
          expect(data_sent['contact_organisation_name_en']).to eq(user.organisations.first.name_en)
          expect(data_sent['contact_organisation_name_zh_tw']).to eq(user.organisations.first.name_zh_tw)
        end

        sendgrid.send_appointment_confirmation_email order
      end


      it "should send the order's information" do
        expect(sendgrid).to receive(:send_email) do
          data_sent = sendgrid.substitution_hash
          expect(data_sent['order_code']).to eq(order.code)
          expect(data_sent['scheduled_at']).to eq(order.order_transport.scheduled_at.in_time_zone.strftime("%e %b %Y %H:%M%p"))
          expect(data_sent['client']).not_to be_nil
          expect(data_sent['client'][:name]).to eq(order.beneficiary.first_name + ' ' + order.beneficiary.last_name)
          expect(data_sent['client'][:phone]).to eq(order.beneficiary.phone_number)
          expect(data_sent['client'][:id_type]).to eq(order.beneficiary.identity_type.name_en)
          expect(data_sent['client'][:id_no]).to eq(order.beneficiary.identity_number)
        end
        sendgrid.send_appointment_confirmation_email order
      end
    end

  end
end
