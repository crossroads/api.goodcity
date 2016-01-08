require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many :packages }
  end

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:area).of_type(:string) }
    it { is_expected.to have_db_column(:building).of_type(:string) }
    it { is_expected.to have_db_column(:stockit_id).of_type(:integer) }
  end
end
