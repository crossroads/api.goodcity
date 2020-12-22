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
          }.to raise_error(ActiveRecord::RecordInvalid)
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
        expect { p1.reload.destroy }.not_to change(PackageSet, :count)
        expect { p2.reload.destroy }.to change(PackageSet, :count).by(-1)
      end
    end
  end

  describe "Package Set initialization" do
    let(:package_set) { create(:package_set) }
    let(:package) { create(:package) }
    let(:item) { create(:item) }
    let(:sibling_1) { create(:package, item: item) }
    let(:sibling_2) { create(:package, item: item) }
    let(:sibling_3) { create(:package, item: item) }
    let(:sibling_4) { create(:package, item: item, package_set: package_set) }

    describe "when the type of an item is set" do
      let(:item) { create(:item, package_type_id: nil) }

      before { touch(item, sibling_1, sibling_2, sibling_3) }

      it "adds the item's packages to a set of the same type" do
        expect {
          item.update(package_type: package_type)
        }.to change(PackageSet, :count).from(0).to(1)
      end
    end

    describe "on creation of packages" do
      before { touch(package_set) }

      it 'is not assigned a package set if it doesnt have sibling packages' do
        expect { touch(package) }.not_to change(PackageSet, :count)
        expect(package.package_set_id).to be_nil
      end

      it 'is assigned a package set if it has sibling packages' do
        expect { touch(sibling_1) }.not_to change(PackageSet, :count)
        expect { touch(sibling_2) }.to change(PackageSet, :count).by(1)

        expect(sibling_1.reload.package_set_id).to eq(sibling_2.reload.package_set_id)

        expect { touch(sibling_3) }.not_to change(PackageSet, :count)
        expect(sibling_3.reload.package_set_id).to eq(sibling_2.reload.package_set_id)
      end

      it 'is assigned a package set with a description equal to the package type' do
        touch(sibling_1, sibling_2)
        expect(sibling_1.reload.package_set.description).to eq(item.package_type.name_en)
      end

      it 'it can be created with an explicit set which is different from the siblings' do
        expect([sibling_1, sibling_2, sibling_3].map(&:reload).map(&:package_set_id).uniq.length).to eq(1)

        expect { touch(sibling_4) }.not_to change(PackageSet, :count)
        expect(sibling_4.reload.package_set_id).not_to eq(sibling_1.reload.package_set_id)
      end
    end
  end
end
