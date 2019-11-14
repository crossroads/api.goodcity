require 'rails_helper'

RSpec.describe Country, type: :model do
  before do
    create(:country, name_en: "India")
    create(:country, name_en: "Indonesia")
    create(:country, name_en: "Hongkong")
    create(:country, name_en: "China")
    create(:country, name_en: "Australia")
  end

  describe "search country" do
    it "filters out coutries" do
      expect(Country.search("Ind").count).to eq(2)
    end

    it "return null if nothing matches" do
      expect(Country.search("Fra").count).to eq(0)
    end
  end
end
