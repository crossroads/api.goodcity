require "rails_helper"

RSpec.describe GoodcityMailer, type: :mailer do
  let(:user) { create(:user, :charity) }
  let(:order) { create(:order, created_by: user) }

  after(:each) do
    I18n.locale = :en
  end

  describe 'send_pin_email' do
    let(:mailer) { GoodcityMailer.with(user_id: user.id).send_pin_email }
    %w[en zh-tw].each do |locale|
      I18n.locale = locale
      it "sets subject in #{locale} locale" do
        expect(mailer.subject).to eq(I18n.t('email.subject.login'))
      end
    end

    it 'handles any SMTP errors' do
      allow_any_instance_of(ApplicationMailer).to receive(:capture_smtp_errors).with(Timeout::Error)
      allow_any_instance_of(GoodcityMailer).to receive(:send_pin_email).and_raise(Timeout::Error)
      GoodcityMailer.send_pin_email
    end
  end
end
