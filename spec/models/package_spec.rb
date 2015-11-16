require 'rails_helper'

RSpec.describe Package, type: :model do

  describe "Associations" do
    it { is_expected.to belong_to :item }
    it { is_expected.to belong_to :package_type }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:length).of_type(:integer)}
    it{ is_expected.to have_db_column(:width).of_type(:integer)}
    it{ is_expected.to have_db_column(:height).of_type(:integer)}
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:notes).of_type(:text)}
    it{ is_expected.to have_db_column(:state).of_type(:string)}
    it{ is_expected.to have_db_column(:received_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:rejected_at).of_type(:datetime)}
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:package_type_id) }

    let(:attributes) { [:width, :length, :height] }
    it { attributes.each { |attribute| is_expected.to allow_value(nil).for(attribute) } }

    it do
      [:quantity, :length].each do |attribute|
        is_expected.to_not allow_value(0).for(attribute)
        is_expected.to_not allow_value(100000000).for(attribute)
        is_expected.to allow_value(rand(1..99999999)).for(attribute)
      end
    end

    it do
      [:width, :height].each do |attribute|
        is_expected.to_not allow_value(0).for(attribute)
        is_expected.to_not allow_value(100000).for(attribute)
        is_expected.to allow_value(rand(1..99999)).for(attribute)
      end
    end
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end
end
