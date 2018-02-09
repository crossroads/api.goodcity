require 'rails_helper'

RSpec.describe OrdersPurpose, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to :order }
    it { is_expected.to belong_to :purpose }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:purpose_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:order_id).of_type(:integer)}
  end
end
