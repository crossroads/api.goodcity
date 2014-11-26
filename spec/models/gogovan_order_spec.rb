require 'rails_helper'

RSpec.describe GogovanOrder, type: :model do
  describe 'Association' do
    it { should have_one :delivery }
  end

  describe 'Database columns' do
    it{ should have_db_column(:booking_id).of_type(:integer)}
    it{ should have_db_column(:status).of_type(:string)}
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
end
