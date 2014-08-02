require 'rails_helper'

RSpec.describe Image, type: :model do

  describe 'Associations' do
    it { should belong_to :parent }
  end

  describe 'Database Columns' do
    it { should have_db_column(:order).of_type(:integer) }
    it { should have_db_column(:image_id).of_type(:string) }
    it { should have_db_column(:favourite).of_type(:boolean) }
    it { should have_db_column(:order).of_type(:integer) }
    it { should have_db_column(:parent_type).of_type(:string) }
    it { should have_db_column(:parent_id).of_type(:integer) }
  end

  describe 'Scope Methods' do
    let!(:images) { create_list :image, 3 }
    let!(:favourite_image) { create :favourite_image }

    it 'favourites' do
      expect(Image.favourites).to eq( [favourite_image] )
    end

    it 'image_identifiers' do
      expect(Image.image_identifiers).to eq( Image.all.order(:id).pluck(:image_id) )
    end
  end

  describe 'Instance Methods' do
    let!(:favourite_image) { create :favourite_image }
    let!(:image) { create :image }

    it 'set_favourite' do
      expect{ image.set_favourite }.to change { image.favourite }.to(true)
    end

    it 'remove_favourite' do
      expect{
        favourite_image.remove_favourite
      }.to change { favourite_image.favourite }.to(false)
    end
  end
end
