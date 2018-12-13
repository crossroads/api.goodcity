require 'rails_helper'

RSpec.describe Organisation, type: :model do
  describe "Database columns" do
    it { is_expected.to have_db_column(:name_en).of_type(:string) }
    it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
    it { is_expected.to have_db_column(:organisation_type_id).of_type(:integer) }
    it { is_expected.to have_db_column(:description_en).of_type(:text) }
    it { is_expected.to have_db_column(:description_zh_tw).of_type(:text) }
    it { is_expected.to have_db_column(:registration).of_type(:string) }
    it { is_expected.to have_db_column(:website).of_type(:string) }
    it { is_expected.to have_db_column(:country_id).of_type(:integer) }
    it { is_expected.to have_db_column(:district_id).of_type(:integer) }
  end

  describe "Associations" do
    it { is_expected.to belong_to :organisation_type }
    it { is_expected.to belong_to :country }
    it { is_expected.to belong_to :district }
    it { is_expected.to have_many :organisations_users }
    it { is_expected.to have_many(:users).through(:organisations_users) }
  end

  describe 'Class Methods' do
    describe '.search' do
      context 'when name_en and name_zh_tw both are pesent' do
        let(:organisation) { create :organisation, name_en: "ZUNI ICOSAHEDRON", name_zh_tw: "進念二十面體" }

        it 'performs case insensitive search for organisation with matching name_en' do
          expect(Organisation.search("zun")).to include(organisation)
          expect(Organisation.search("ZUNI")).to include(organisation)
        end

        it 'performs case insensitive search for organisation with matching name_zh_tw' do
          expect(Organisation.search("進念")).to include(organisation)
        end
      end

      context 'when name_zh_tw is nil' do
        it 'performs case insensitive search for organisation with matching name_en' do
          organisation = create :organisation, name_en: "ZUNI ICOSAHEDRON"
          expect(Organisation.search("zun")).to include(organisation)
        end
      end

      context 'when name_en is nil' do
        it 'performs case insensitive search for organisation with matching name_en' do
          organisation = create :organisation, name_zh_tw: "進念二十面體"
          expect(Organisation.search("進念二十")).to include(organisation)
        end
      end
    end
  end

  describe 'Instance Methods' do
    describe '#name_as_per_locale' do
      let(:organisation) { create :organisation }

      it 'returns name_en if locale is en' do
        in_locale 'en' do
          expect(organisation.name_as_per_locale).to eq(organisation.name_en)
        end
      end

      it 'returns name_zh_tw if locale is zh-tw' do
        in_locale 'zh-tw' do
          expect(organisation.name_as_per_locale).to eq(organisation.name_zh_tw)
        end
      end
    end
  end
end
