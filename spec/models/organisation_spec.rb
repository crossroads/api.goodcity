require 'rails_helper'

RSpec.describe Organisation, type: :model do
  let!(:country) { create(:country, name_en: DEFAULT_COUNTRY) }

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

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name_en }
    it { is_expected.to validate_uniqueness_of :name_en }
    it { is_expected.to validate_presence_of :organisation_type_id }
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

      context 'typo tolerance' do
        let(:organisation) { create :organisation, name_en: "The Steve Inc."}

        before { touch(organisation) }

        it { expect(Organisation.search("Stve")).to include(organisation) }
        it { expect(Organisation.search("steve el")).to include(organisation) }
        it { expect(Organisation.search("The Inc.")).to include(organisation) }
        it { expect(Organisation.search("Inc Steve The.")).to include(organisation) }
        it { expect(Organisation.search("The Inc.")).to include(organisation) }
        it { expect(Organisation.search("The Stephen Inc.")).to include(organisation) }
        it { expect(Organisation.search("Ic Steve The.")).to include(organisation) }
        it { expect(Organisation.search("Patrick Corp")).not_to include(organisation) }
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

  describe '#trim_name' do
    it 'trims and converts name to upcase before save' do
      organisation = build(:organisation, name_en: 'good city   ')
      organisation.save
      expect(organisation.reload.name_en).to eq('good city')
    end
  end

  describe 'set_default_country' do
    context 'if country is not specified' do
      it 'sets default country to China' do
        organisation = build(:organisation, country_id: nil)
        organisation.save
        expect(organisation.reload.country.name_en).to eq(DEFAULT_COUNTRY)
      end
    end

    context 'if country is specified' do
      it 'does not changes the country value' do
        organisation = build(:organisation)
        name = organisation.country.name_en
        organisation.save
        expect(organisation.reload.country.name_en).to eq(name)
      end
    end
  end
end
