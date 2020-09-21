require 'rails_helper'

class TokenValidatableFakeController < ActionController::Base
  include TokenValidatable
end

describe TokenValidatableFakeController do

  let(:api_jwt) { Token.new.generate_api_token({}) }
  let(:otp_jwt) { Token.new.generate_otp_token({}) }
  let(:api_token) { Token.new(bearer: api_jwt) }
  let(:otp_token) { Token.new(bearer: otp_jwt) }
  let(:user) { create :user, disabled: false }
  let(:disabled_user) { create :user, disabled: true }

  describe "validate_token" do

    describe "with valid API token" do
      before do
        expect(Token).to receive(:new).and_return(api_token)
        expect(api_token).to receive(:valid?).and_return(true)
      end
      it "should be authorized with enabled user" do
        User.current_user = user
        expect{ subject.send(:validate_token) }.to_not throw_symbol(:warden)
      end
    end

    describe "with valid OTP token" do
      before do
        expect(Token).to receive(:new).and_return(otp_token)
        expect(otp_token).to receive(:valid?).and_return(true)
      end
      it "should throw unauthorized error" do
        User.current_user = user
        expect{ subject.send(:validate_token) }.to throw_symbol(:warden)
      end
    end

    describe "with invalid token" do
      before do
        expect(Token).to receive(:new).and_return(api_token)
        expect(api_token).to receive(:valid?).and_return(false)
      end
      it "should throw unauthorized error if user is enabled" do
        User.current_user = user
        expect{ subject.send(:validate_token) }.to throw_symbol(:warden)
      end
      it "should throw unauthorized error if user is disabled" do
        User.current_user = disabled_user
        expect{ subject.send(:validate_token) }.to throw_symbol(:warden)
      end
    end

  end
end
