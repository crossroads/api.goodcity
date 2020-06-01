require 'rails_helper'

RSpec.describe PackageSet, type: :model do
  let(:package_type) { create(:package_type, code: 'AFO') }
  let(:other_package_type) { create(:package_type, code: 'BBC') }

  before { User.current_user = create(:user) }

  describe 'Associations' do
    it { is_expected.to have_many :packages }
  end

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:package_type_id).of_type(:integer) }
  end

  describe 'Lifecycle' do
    let(:package_set) { create(:package_set, package_type: package_type) }
    let(:empty_package_set) { create(:package_set, package_type: package_type) }
    let(:packages) { 3.times.map { create(:package, package_set_id: package_set.id) }}

    before(:each) do
      touch(package_set, packages)
      expect(package_set.reload.packages).to match_array(packages)
      expect(packages.map(&:package_set_id).uniq).to eq([package_set.id])
    end

    describe 'on destroy' do
      it 'unsets the package_set_id of its packages' do
        package_set.destroy!
        expect(packages.map(&:reload).map(&:package_set_id).uniq).to eq([nil])
      end
    end

    describe 'on update' do
      context 'of the package_type' do
        it 'prevents changing the type of a set with packages' do
          expect {
            package_set.update!(package_type: other_package_type)
          }.to raise_error(ActiveRecord::RecordInvalid).with_message(/Changing the set's type is not allowed/)
        end

        it 'allows changing the type of a set with no packages' do
          expect {
            empty_package_set.update!(package_type: other_package_type)
          }.to change {
            empty_package_set.reload.package_type.code
          }.from('AFO').to('BBC')
        end
      end
    end

    describe 'auto destroys when the number of packages is less than 2' do
      it 'if the packages get unassigned from the set' do
        p1, p2 = packages
        expect { p1.update(package_set_id: nil) }.not_to change(PackageSet, :count)
        expect { p2.update(package_set_id: nil) }.to change(PackageSet, :count).by(-1)
      end

      it 'if the packages are destroyed' do
        p1, p2 = packages
        expect { p1.destroy }.not_to change(PackageSet, :count)
        expect { p2.destroy }.to change(PackageSet, :count).by(-1)
      end
    end
  end
end
