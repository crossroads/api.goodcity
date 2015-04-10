require 'rails_helper'

RSpec.describe GogovanOrder, type: :model do
  describe 'Association' do
    it { is_expected.to have_one :delivery }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:booking_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:status).of_type(:string)}
    it{ is_expected.to have_db_column(:price).of_type(:float)}
    it{ is_expected.to have_db_column(:driver_name).of_type(:string)}
    it{ is_expected.to have_db_column(:driver_mobile).of_type(:string)}
    it{ is_expected.to have_db_column(:driver_license).of_type(:string)}
  end

  describe 'save_booking' do
    let(:booking_id) { rand(1000000..9999999) }
    it 'should create record with booking_id' do
      expect{
        GogovanOrder.save_booking(booking_id)
      }.to change(GogovanOrder, :count).by(1)
      expect(GogovanOrder.last.booking_id).to eq(booking_id)
    end
  end

  describe '#update_status' do
    it 'should update status of order' do
      order = create :gogovan_order
      expect{
        order.update_status("cancelled")
      }.to change(order, :status).from('pending').to('cancelled')
    end
  end

  describe '#need_polling?' do
    it 'should return true if status is pending/active' do
      order = build :gogovan_order, status: 'active'
      expect(order.need_polling?).to eq(true)
    end

    it 'should return true if status is completed/cancelled' do
      order = build :gogovan_order, status: 'completed'
      expect(order.need_polling?).to eq(false)
    end
  end

  describe '#cancelled?' do
    let(:order) { build :gogovan_order }

    it 'should return true if status changed to cancelled' do
      order.status = 'cancelled'
      expect(order.cancelled?).to eq(true)
    end

    it 'should return false if status changed to other than cancelled' do
      order.status = 'active'
      expect(order.cancelled?).to eq(false)
    end
  end

  describe 'callbacks' do
    it { is_expected.to callback(:cancel_order).before(:destroy) }
  end
end
