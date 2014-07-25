require 'rails_helper'

RSpec.describe Image, type: :model do

  describe 'Associations' do
    it { should belong_to :parent }
  end

  describe 'Database Columns' do
    it { should have_db_column(:order).of_type(:integer) }
    it { should have_db_column(:image).of_type(:string) }
    it { should have_db_column(:favourite).of_type(:boolean) }
    it { should have_db_column(:order).of_type(:integer) }
    it { should have_db_column(:parent_type).of_type(:string) }
    it { should have_db_column(:parent_id).of_type(:integer) }
  end

  describe 'set_image_public_id' do
    let!(:image) { create :image }

    it "should prepend 'v' to image string" do
      expect(image.image.start_with? 'v').to eq(true)
    end
  end
end
