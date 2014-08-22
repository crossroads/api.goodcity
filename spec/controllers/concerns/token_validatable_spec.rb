require 'rails_helper'

class TokenValidatableFakeController < ActionController::Base
  include TokenValidatable
end

describe TokenValidatableFakeController do

  let(:token) { Token.new }
  before { expect(Token).to receive(:new).and_return(token) }

  it "should successfully validate a good token" do
    expect(token).to receive(:valid?).and_return(true)
    subject.send(:validate_token)
  end

  it "should throw unauthorized error if token validation fails" do
    expect(token).to receive(:valid?).and_return(false)
    expect{ subject.send(:validate_token) }.to throw_symbol(:warden)
  end

end
