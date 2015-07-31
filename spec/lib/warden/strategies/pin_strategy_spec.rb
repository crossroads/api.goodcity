require 'rails_helper'

describe Warden::Strategies::PinStrategy, type: :controller do

  let(:env) { {} }
  let(:params) { {} }
  let(:pin) { "1234" }
  let(:otp_auth_key) { "zKER89Q/NRm0TXhqGII+Ww==" }
  let(:strategy) { Warden::Strategies::PinStrategy.new(env) }
  let(:auth_token) { build :auth_token }
  let(:user) { build :user }

  before { allow(strategy).to receive(:request).and_return(double( params: params)) }

  context 'valid?' do
    context "with valid params" do
      let(:params) { {'pin' => pin, 'otp_auth_key' => otp_auth_key} }
      it { expect(strategy.valid?).to eql(true) }
    end
    context "with no params" do
      it { expect(strategy.valid?).to eql(false) }
    end
    context "with blank params" do
      let(:params) { {'pin' => '', 'otp_auth_key' => ''} }
      it { expect(strategy.valid?).to eql(false) }
    end
    context "with just pin" do
      let(:params) { {'pin' => pin} }
      it { expect(strategy.valid?).to eql(false) }
    end
    context "with just otp_auth_key" do
      let(:params) { {'otp_auth_key' => otp_auth_key} }
      it { expect(strategy.valid?).to eql(false) }
    end
  end

  context "authenticate" do

    context "with valid auth_token" do
      let(:params) { {'pin' => pin, 'otp_auth_key' => otp_auth_key} }
      before { expect(AuthToken).to receive(:find_by_otp_auth_key).with(otp_auth_key).and_return(auth_token) }
      before { Rails.application.secrets.appstore_reviewer_login = {} }

      context "and successful otp authentication" do
        before { expect(auth_token).to receive(:authenticate_otp).with(pin, {drift: ENV['OTP_CODE_VALIDITY'].to_i}).and_return(true) }

        context "and user found" do
          before { expect(auth_token).to receive(:user).and_return(user).at_least(:once) }
          it "should be success!" do
            expect(strategy).to receive(:success!).with(user)
            strategy.authenticate!
          end
        end

        context "and user not found" do
          before { expect(auth_token).to receive(:user).and_return(nil).at_least(:once) }
          it "should return failure" do
            expect(strategy.authenticate!).to equal(:failure)
          end
        end

      end

      context "and unsuccessful otp authentication" do
        before { expect(auth_token).to receive(:authenticate_otp).and_return(false) }
        it "should return failure" do
          expect(strategy.authenticate!).to equal(:failure)
        end
      end

      context "with appstore reviewer login credentials" do
        let(:params) { {'pin' => '1234', 'otp_auth_key' => otp_auth_key} }
        let(:user) { build :user, mobile: "+85255555555" }
        before { expect(auth_token).to receive(:user).and_return(user).at_least(:once) }
        before { expect(Rails.application.secrets).to receive(:appstore_reviewer_login).and_return({"number"=>"+85255555555","pin"=>"1234"}).at_least(:once) }
        it "should return success" do
          expect(strategy).to receive(:success!)
          strategy.authenticate!
        end
      end
    end

    context "with invalid auth_token" do
      before { expect(AuthToken).to receive(:find_by_otp_auth_key).and_return(nil) }
      it "should return failure" do
        expect(strategy.authenticate!).to equal(:failure)
      end
    end

  end

end
