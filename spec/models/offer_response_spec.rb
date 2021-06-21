require 'rails_helper'

RSpec.describe OfferResponse, type: :model do

  describe "Associations" do
    it { is_expected.to have_many :offers }
    it { is_expected.to have_many :users }
    it { is_expected.to have_many :messages }
  end


  describe "Database Columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer) }
    it { is_expected.to have_db_column(:offer_id).of_type(:integer) }
  end
end
