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


  describe "handle heic images" do
    it "converts heic image to jpg before save" do
      package = create :package
      cloudinary_id = "1416897663/szfmfbmjeq6aphyfflmg.heic"
      image = Image.create(imageable: package, cloudinary_id: cloudinary_id)
      expect(image.cloudinary_id).to eq("1416897663/szfmfbmjeq6aphyfflmg.jpg")
    end
  end
end
