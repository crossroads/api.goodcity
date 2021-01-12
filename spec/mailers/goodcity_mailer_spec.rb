require "rails_helper"

RSpec.describe GoodcityMailer, type: :mailer do
  let(:user) { create(:user, :charity) }
  let(:order) { create(:order, created_by: user) }
  before(:each) do
    I18n.locale = 'en'
  end

  describe 'send_pin_email' do
    let(:mailer) { GoodcityMailer.with(user_id: user.id).send_pin_email }
    %w[en zh-tw].each do |locale|
      I18n.locale = locale
      it "sets subject in #{locale} locale" do
        expect(mailer.subject).to eq(I18n.t('email.subject.login'))
      end
    end
  end
end
