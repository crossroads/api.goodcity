require 'rails_helper'

class TokenValidatableFakeController < ActionController::Base
  include TokenValidatable
end

describe TokenValidatableFakeController do

  let(:token) { Token.new }
  before do
    expect(Token).to receive(:new).and_return(token)
    User.current_user = create :user, disabled: true
  end

  it "should successfully validate a good token and valid user" do
    User.current_user = create :user
    expect(token).to receive(:valid?).and_return(true)
    subject.send(:validate_token)
  end

  it "should throw unauthorized error if token validation fails" do
    expect(token).to receive(:valid?).and_return(false)
    expect{ subject.send(:validate_token) }.to throw_symbol(:warden)
  end

  it "should throw unauthorized error if user is disabled" do
    expect(token).to receive(:valid?).and_return(true)
    expect{ subject.send(:validate_token) }.to throw_symbol(:warden)
  end

end
