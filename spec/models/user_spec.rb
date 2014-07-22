require 'rails_helper'

describe User, :type => :model do
  describe '.signup' do

    it 'has valid mobile number' do

    end

    it 'save the mobile, firstname, lastname, district details' do
      mobile = '+852 111 111 1111'
    end

    it 'on save generate OTP SECRET KEY' do
    end

    it 'generate OTP CODE' do

    end

    it 'Sms OTP CODE' do

    end

    it 'authentication successful with valid OTP CODE' do
    end

    it 'authentication failed with invalid OTP Code' do
    end
  end

  describe '.login' do
    it 'mobile number already existed for the user' do
    end
  end
end
