require 'rails_helper'

RSpec.describe ItemType, :type => :model do

  describe "Associations" do
    it { is_expected.to have_many :items }
    it { is_expected.to have_many :packages }
    it { is_expected.to belong_to :parent }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name_en) }
    it { is_expected.to validate_uniqueness_of(:name_en) }
  end
end
