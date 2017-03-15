require "rails_helper"
require "goodcity/organisation_populator"

describe Goodcity::OrganisationPopulator do
  let(:organisation_populator) { Goodcity::OrganisationPopulator.new }
  let(:file)                   { File.read("#{Rails.root}/spec/fixtures/organisation.json")}
  let!(:country)               { FactoryGirl.create(:country, name_en: "China - Hong Kong (Special Administrative Region)") }

  before do
    stub_request(:get, /goodcitystorage.blob.core.windows.net/).
      with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: file , headers: {}).response.body
  end

  context "populate organisation" do
    before { organisation_populator.run }
    it ":count created data" do
      expect(Organisation.count).to eq(JSON.parse(file).count)
    end
    it ":created data" do
      JSON.parse(file).each do |data|
        organisation_fields_mapping = Goodcity::OrganisationPopulator::ORGANISATION_MAPPING.keep_if { |k, v| data.key? v }
        organisation = Organisation.find_by_registration(data['org_id'])
        organisation_fields_mapping.each do |organisation_column, data_key|
          expect(organisation[organisation_column.to_sym]).to eq(data[data_key])
        end
      end
    end
  end

  context "update organisation" do
    before do
      @registration_id = [ "91/09657", "91/15022" ]
      Organisation.create(registration: @registration_id[0], website: "")
      Organisation.create(registration: @registration_id[1], name_en: "abcd")
    end

    describe ":updated data" do
      it "Create only new records" do
        expect {
        organisation_populator.run
        }.to change(Organisation, :count).by(6)
      end

      it ":update the existing records" do
        JSON.parse(file).each do |data|
          @registration_id.each do |reg_id|
            if(data['org_id'] == reg_id)
              organisation = Organisation.find_by(registration: data['org_id'])
              expect(organisation.name_en).to_not eq(data['name_en'])
              expect(organisation.website).to_not eq(data['url'])
            end
          end
        end
      end
    end

    context "default_country" do
      
      it do
        expect(organisation_populator.send(:default_country).name_en).to eq(Goodcity::OrganisationPopulator::COUNTRY_NAME_EN)
      end
    end

    context "organisation_type" do
      it do
        expect(organisation_populator.send(:organisation_type).name_en).to eq(Goodcity::OrganisationPopulator::ORGANISATION_TYPE_NAME)
      end
    end

  end

end
