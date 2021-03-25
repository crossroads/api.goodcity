require 'rails_helper'

RSpec.describe GoodcityMailer, type: :mailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  let(:user) { create(:user, :charity) }
  subject(:subject) { described_class.with(user_id: user.id) }

  after(:each) do
    I18n.locale = :en
  end

  describe 'send_pin_email' do
    let(:mailer) { subject.send_pin_email }

    it 'sets proper from and to address' do
      expect(mailer).to deliver_from(GOODCITY_FROM_EMAIL)
      expect(mailer).to deliver_to(user.email)
    end

    %w[zh-tw en].each do |locale|
      context "for #{locale} language" do
        let(:user) { create(:user, :charity, preferred_language: locale) }
        it "sets subject in #{locale} locale" do
          I18n.with_locale(locale) do
            expect(mailer.subject).to eq(I18n.t('email.subject.login'))
          end
        end
      end
    end

    it 'handles any SMTP errors' do
      allow_any_instance_of(ApplicationMailer).to receive(:capture_smtp_errors).with(Timeout::Error)
      allow_any_instance_of(GoodcityMailer).to receive(:send_pin_email).and_raise(Timeout::Error)
      GoodcityMailer.send_pin_email
    end
  end
end
