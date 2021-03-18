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
      it 'sends ' do

      end
    end

    it 'sends pin on changing mobile number' do

    end
  end
end
