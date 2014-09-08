require 'rails_helper'

RSpec.describe Offer, type: :model do

  it_behaves_like 'paranoid'

  describe 'Associations' do
    it { should belong_to :created_by }
    it { should have_many :messages }
    it { should have_many :items }
  end

  describe 'Database Columns' do
    it { should have_db_column(:language).of_type(:string) }
    it { should have_db_column(:state).of_type(:string) }
    it { should have_db_column(:origin).of_type(:string) }
    it { should have_db_column(:stairs).of_type(:boolean) }
    it { should have_db_column(:parking).of_type(:boolean) }
    it { should have_db_column(:estimated_size).of_type(:string) }
    it { should have_db_column(:notes).of_type(:text) }
    it { should have_db_column(:created_by_id).of_type(:integer) }
  end

  describe 'set_submit_time' do
    let!(:offer) { create :offer }
    it 'should set submitted_at time to current_time' do
      expect{
        offer.update_attributes(state: 'submitted')
      }.to change(offer, :submitted_at)
    end
  end

  describe 'valid_state?' do
    it 'should verify state valid or not' do
      expect(Offer.valid_state?('submitted')).to be true
      expect(Offer.valid_state?('submit')).to be false
    end
  end

  describe 'valid_states' do
    it 'should return list of valid states' do
      expect(Offer.valid_states).to eq(['draft', 'submitted'])
    end
  end

end
