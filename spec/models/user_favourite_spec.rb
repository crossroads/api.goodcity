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
    let(:package_type) { create :package_type }
    let(:location) { create :location }

    before { User.current_user = user }

    it 'creates user_favourites record for model and its associations' do
      expect {
        create :package, package_type_id: package_type.id
      }.to change(UserFavourite, :count).by(2)
    end

    it 'creates user_favourites record for models relationships assigned to "auto_favourite_relations"' do
      expect {
        create :package, package_type: package_type
      }.to change(UserFavourite, :count).by(2)
      expect(UserFavourite.pluck(:favourite_id)).to include(package_type.id)
    end

    it 'does not create user_favourites record for models relationships assigned to "auto_favourite_relations"' do
      expect {
        create :package, package_type: package_type, location_id: location.id
      }.to change(UserFavourite, :count).by(2)
      expect(UserFavourite.pluck(:favourite_id)).not_to include(location.id)
    end

    context 'when a persistent favourite already exists' do
      let(:package) { create :package, package_type: package_type }
      before do
        UserFavourite.add_user_favourite(package, persistent: true)
      end

      context 'on creating a non persistent favourite for same record' do
        it 'should not create new record' do
          expect {
            UserFavourite.add_user_favourite(package, persistent: false)
          }.not_to change(UserFavourite, :count)
        end
      end
    end
  end
end
