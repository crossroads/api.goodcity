require "rails_helper"
  #  {
  #   :detail_type
  #   :detail_id
  #   detail_attributes: {
  #     :brand,
  #     :model,
  #     :serial_num
  #   }

  describe PackageDetailBuilder do
    let(:detail_attributes) { FactoryBot.attributes_for(:computer).as_json }
    let(:computer) { create :computer }
    let(:params) { FactoryBot.attributes_for(:package, detail_type: "computer", detail_attributes: detail_attributes).as_json }
    let(:detail_type) { params["detail_type"] }
    let(:pkg_builder) { PackageDetailBuilder.new(params) }
    let(:pkg_builder_with_id) { PackageDetailBuilder.new(create :package, detail_type: "computer", detail_id: computer.id) }

    describe "initialize" do
      it "sets instance variables" do
        expect(pkg_builder.detail_type).to eql(params["detail_type"])
        expect(pkg_builder.detail_attributes).to eql(detail_attributes)
      end
    end



    describe "build_detail" do
      it "creates new detail type if id is not present" do
        pkg=pkg_builder
        expect(Computer).to receive(:new).with(detail_attributes)
        pkg.build_or_update_record
      end

      it "saves and returns detail if id is present" do
        pkg_detail = pkg_builder_with_id.build_or_update_record
        expect(pkg_detail).to_not be nil
        expect(pkg_detail.brand).to eq(computer["brand"])
      end
    end
  end
