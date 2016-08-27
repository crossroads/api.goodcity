require 'rails_helper'

RSpec.describe Image, type: :model do

  describe 'Associations' do
    it { is_expected.to belong_to :imageable }
  end

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:cloudinary_id).of_type(:string) }
    it { is_expected.to have_db_column(:favourite).of_type(:boolean) }
    it { is_expected.to have_db_column(:item_id).of_type(:integer) }
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "has_multiple_items" do
    it "should return true if image belong_to multiple-items" do
      image = create :image, :with_item
      copy_image = create :image, :with_item, cloudinary_id: image.cloudinary_id
      expect(image.send(:has_multiple_items)).to be_truthy
    end
  end
end
