require 'rails_helper'

RSpec.describe Stocktake, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many :stocktake_revisions }
    it { is_expected.to belong_to :location }
  end

  describe 'Columns' do
    it { is_expected.to have_db_column(:location_id).of_type(:integer) }
    it { is_expected.to have_db_column(:name).of_type(:string) }
    it { is_expected.to have_db_column(:state).of_type(:string) }
  end
end
