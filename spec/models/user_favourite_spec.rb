require 'rails_helper'

RSpec.describe UserFavourite, type: :model do
  let(:user) { create :user }

  describe "Associations" do
    it { is_expected.to belong_to :favourite }
    it { is_expected.to belong_to :user }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:favourite_type).of_type(:string) }
    it { is_expected.to have_db_column(:favourite_id).of_type(:integer) }
    it { is_expected.to have_db_column(:persistent).of_type(:boolean) }
  end

  describe '#add_user_favourite' do

    before { 
      Package.auto_favourite_relations ['package_type']
      User.current_user = user 
    }

    it 'creates user_favourites record for model' do
      package_type = create :package_type 
      package = create :package, package_type: package_type
      expect(UserFavourite.count).to eq(2)
      expect(UserFavourite.pluck(:favourite_id)).to include(package.id)
    end

    it 'creates user_favourites record for models relationships assigned to "auto_favourite_relations"' do
      package_type = create :package_type 
      package = create :package, package_type: package_type
      expect(UserFavourite.count).to eq(2)
      expect(UserFavourite.pluck(:favourite_id)).to include(package_type.id)
    end

    it 'does not create user_favourites record for models relationships assigned to "auto_favourite_relations"' do
      location = create :location 
      package_type = create :package_type 
      package = create :package, package_type: package_type, location_id: location.id
      expect(UserFavourite.count).to eq(2)
      expect(UserFavourite.pluck(:favourite_id)).not_to include(location.id)
    end
  end
end
