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

  context "#template_id_based_on_locale" do
    it "returns english template constant name if locale is en" do
      I18n.locale = :en
      expect(sendgrid.template_id_based_on_locale).to eq "SENDGRID_PIN_TEMPLATE_ID_EN"
    end

    it "returns chinese template constant name if locale is zh-tw" do
      I18n.locale = :"zh-tw"
      expect(sendgrid.template_id_based_on_locale).to eq "SENDGRID_PIN_TEMPLATE_ID_ZH_TW"
    end
  end

  describe "sms_verification_pin" do
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
end
