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
end
