require 'rails_helper'

RSpec.describe OfferResponse, type: :model do

  describe "Associations" do
    it { is_expected.to belong_to :offer }
    it { is_expected.to belong_to :user }
    it { is_expected.to have_many :messages }
  end


  describe "Database Columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer) }
    it { is_expected.to have_db_column(:offer_id).of_type(:integer) }
  end

  describe "Offer Response " do
    let(:offer) { create :offer }
    let(:user) { create :user }

    before { User.current_user = user }

    it 'creates offer_response record for model and its associations' do
      expect {
        create :offer_response, offer_id: offer.id, user_id: user.id
      }.to change(OfferResponse, :count).by(1)
    end

    it 'does not creates user_favourites record if recode is not unique' do
      create(:offer_response, offer_id: offer.id, user_id: user.id)
      expect {
        create :offer_response, offer_id: offer.id, user_id: user.id
      }.to raise_error( ActiveRecord::RecordNotUnique)
    end
  end
end
