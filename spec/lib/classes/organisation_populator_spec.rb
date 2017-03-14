require "rails_helper"

describe OrganisationPopulator do
  let(:organisation_populator) { OrganisationPopulator.new }
  let(:success_response)    { { "status" => 201 } }
  let(:mock_response)       { double( as_json: success_response ) }
  let(:error_response)      { { "errors" => { "code" => "can't be blank" } } }
  let(:mock_error_response) { double( as_json: error_response ) }
  let(:file)                 { File.read("#{Rails.root}/spec/fixtures/organisation.json")}

  before do
    Country.create(name_en: "China - Hong Kong (Special Administrative Region)")
    stub_request(:get, /goodcitystorage.blob.core.windows.net/). with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}). to_return(status: 200, body: file , headers: {}).response.body
  end

  context "initialization" do
    it "organisation_type" do
      expect(organisation_populator.instance_variable_get(:@organisation_type).name_en).to eq(OrganisationPopulator::ORGANISATION_TYPE_NAME)
    end

    it "country" do
      expect(organisation_populator.instance_variable_get(:@country).name_en).to eq(OrganisationPopulator::COUNTRY_NAME_EN)
    end

    it "url" do
      expect(organisation_populator.instance_variable_get(:@file)).to eq(file)
    end
  end

  context "create populate_organisation_db" do
    before { organisation_populator.populate_organisation_db }
    it do
      expect(organisation_populator.instance_variable_get(:@file).present?).to eq(file.present?)
    end

    it { expect(Organisation.count).to eq(JSON.parse(file).count)}
    it "created data" do
      JSON.parse(file).each do |data|
        organisation_fields_mapping = OrganisationPopulator::ORGANISATION_MAPPING.keep_if { |k, v| data.key? v }
        organisation = Organisation.find_by_registration(data['org_id'])
        organisation_fields_mapping.each do |organisation_column, data_key|
          expect(organisation[organisation_column.to_sym]).to eq(data[data_key])
        end
      end
    end
  end

  context "update populate_organisation_db" do
    before do
      Organisation.create(registration: "91/09657", website: "")
      Organisation.create(registration: "91/15022", name_en: "abcd")
    end

    it "updated data" do
      organisation_populator.populate_organisation_db
      JSON.parse(file).each do |data|
        organisation_fields_mapping = OrganisationPopulator::ORGANISATION_MAPPING.keep_if { |k, v| data.key? v }
        organisation = Organisation.find_by_registration(data['org_id'])
        organisation_fields_mapping.each do |organisation_column, data_key|
          expect(organisation[organisation_column.to_sym]).to eq(data[data_key])
        end
      end
    end
  end

end
