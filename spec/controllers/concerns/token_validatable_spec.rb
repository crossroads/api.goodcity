require 'rails_helper'

class TokenValidatableFakeController < ActionController::Base
  include TokenValidatable
end

describe TokenValidatableFakeController do

  let(:token) { Token.new }
  let(:user) { create :user, disabled: false }
  let(:disabled_user) { create :user, disabled: true }

  before do
    expect(Token).to receive(:new).and_return(token)
  end

  describe "validate_token" do

    describe "with valid token" do
      before do
        expect(token).to receive(:valid?).and_return(true)
      end
      it "should be authorized with enabled user" do
        User.current_user = user
        expect{ subject.send(:validate_token) }.to_not throw_symbol(:warden)
      end
      it "should not be authorized with disabled user" do
        User.current_user = disabled_user
        expect{ subject.send(:validate_token) }.to throw_symbol(:warden)
      end
    end

    describe "with invalid token" do
      before do
        expect(token).to receive(:valid?).and_return(false)
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
