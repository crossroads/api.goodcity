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
    it ":set organisation_type" do
      expect(organisation_populator.instance_variable_get(:@organisation_type).name_en).to eq(OrganisationPopulator::ORGANISATION_TYPE_NAME)
    end

    it ":set country" do
      expect(organisation_populator.instance_variable_get(:@country).name_en).to eq(OrganisationPopulator::COUNTRY_NAME_EN)
    end

    it ":set url" do
      expect(organisation_populator.instance_variable_get(:@file)).to eq(file)
    end
  end

  context "populate organisation" do
    before { organisation_populator.populate_organisation_db }
    it do
      expect(organisation_populator.instance_variable_get(:@file).present?).to eq(file.present?)
    end

    it ":count created data" do
      expect(Organisation.count).to eq(JSON.parse(file).count)
    end
    it ":created data" do
      JSON.parse(file).each do |data|
        organisation_fields_mapping = OrganisationPopulator::ORGANISATION_MAPPING.keep_if { |k, v| data.key? v }
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
        organisation_populator.populate_organisation_db
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
  end

end
