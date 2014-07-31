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

  describe 'Scope Methods' do
    let!(:images) { create_list :image, 3 }
    let!(:fav_image) { create :favourite_image }

    it 'get_favourite' do
      expect(Image.get_favourite).to eq(fav_image)
    end
  end

  describe 'Instance Methods' do
    let!(:fav_image) { create :favourite_image }
    let!(:image) { create :image }

    it 'set_favourite' do
      expect{ image.set_favourite }.to change { image.favourite }.to(true)
    end

    it 'remove_favourite' do
      expect{
        fav_image.remove_favourite
      }.to change { fav_image.favourite }.to(false)
    end
  end
end
