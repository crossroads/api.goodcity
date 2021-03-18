# frozen_string_literal: true

require 'rails_helper'
describe PinManager do
  let(:user) { create(:user, :with_token) }

  describe '.initialize' do
    it 'intializes instance variables' do
      pin_manager = PinManager.new(user.mobile, user.id, DONOR_APP)

      expect(pin_manager.instance_variable_get(:@user)).to eq(user)
      expect(pin_manager.instance_variable_get(:@mobile_raw)).to eq(user.mobile)
      expect(pin_manager.instance_variable_get(:@mobile)).to be_an_instance_of(Mobile)
      expect(pin_manager.instance_variable_get(:@app_name)).to eq(DONOR_APP)
    end
  end

  describe '#formulate_auth_key' do
    context 'if user_id is not present' do
      it 'return otp_auth_key' do
        res = PinManager.formulate_auth_key(user.mobile, nil, DONOR_APP)
        expect(res).to eq(user.most_recent_token.otp_auth_key)
      end

      it 'will send pin for login' do
        expect_any_instance_of(PinManager).to receive(:send_pin_for_login)
        PinManager.formulate_auth_key(user.mobile, nil, DONOR_APP)
      end
    end

    context 'if user_id is present' do
      it 'return otp_auth_key' do
        res = PinManager.formulate_auth_key('+85290369036', user.id, DONOR_APP)
        expect(res).to eq(user.most_recent_token.otp_auth_key)
      end

      it 'will send pin for changing mobile number' do
        expect_any_instance_of(PinManager).to receive(:send_pin_for_new_mobile_number)
        PinManager.formulate_auth_key('+85290369036', user.id, DONOR_APP)
      end
    end
  end

  describe '.send_pin_for_login' do
    let(:mobile) { user.mobile }
    let(:app) { DONOR_APP }
    let(:pin_manager) { PinManager.new(mobile, nil, app) }

    it 'sends otp' do
      user = pin_manager.instance_variable_get(:@user)
      expect(user).to receive(:send_verification_pin).with(DONOR_APP, user.mobile)
      pin_manager.send_pin_for_login
    end

    it 'returns otp_auth_key' do
      expect(pin_manager.send_pin_for_login).to eq(user.most_recent_token.otp_auth_key)
    end

    context 'for invalid mobile number' do
      let(:mobile) { '+9111231' }

      it 'raises InvalidMobileError' do
        expect { pin_manager.send_pin_for_login }.to raise_error(Goodcity::InvalidMobileError)
      end
    end

    context 'if user is not allowed to login' do
      let(:app) { STOCK_APP }

      it 'raises AccessDeniedError' do
        expect { pin_manager.send_pin_for_login }.to raise_error(Goodcity::AccessDeniedError)
      end
    end
  end

  describe '.send_pin_for_new_mobile_number' do
    let(:mobile) { '+85290369036' }
    let(:app) { DONOR_APP }
    let(:pin_manager) { PinManager.new(mobile, user.id, app) }

    it 'sends otp' do
      user = pin_manager.instance_variable_get(:@user)
      expect(user).to receive(:send_verification_pin).with(DONOR_APP, mobile)
      pin_manager.send_pin_for_new_mobile_number
    end

    it 'returns otp_auth_key' do
      expect(pin_manager.send_pin_for_new_mobile_number).to eq(user.most_recent_token.otp_auth_key)
    end

    context 'for invalid phone number' do
      let(:mobile) { '+9190369036' }

      it 'raises InvalidMobileError' do
        expect { pin_manager.send_pin_for_new_mobile_number }.to raise_error(Goodcity::InvalidMobileError)
      end
    end

    context 'if duplicate phone number' do
      let!(:mobile) { create(:user).mobile }

      it 'raises Goodcity::InvalidParamsError' do
        expect { pin_manager.send_pin_for_new_mobile_number }.to raise_error(Goodcity::InvalidParamsError)
      end
    end

    context 'if user is not allowed to login' do
      let(:app) { STOCK_APP }

      it 'raises AccessDeniedError' do
        expect { pin_manager.send_pin_for_new_mobile_number }.to raise_error(Goodcity::AccessDeniedError)
      end
    end
  end
end
