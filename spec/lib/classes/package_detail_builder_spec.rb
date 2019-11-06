require "rails_helper"
  #  {
  #   :detail_type
  #   detail_attributes: {
  #     :brand,
  #     :model,
  #     :serial_num
  #   }

  describe PackageDetailBuilder do
    let(:detail_attributes) { FactoryBot.attributes_for(:computer).as_json }
    let(:params) { FactoryBot.attributes_for(:package, detail_type: "computer", detail_attributes: detail_attributes).as_json }
    let(:detail_type) { params["detail_type"] }
    let(:pkg_builder) { PackageDetailBuilder.new(params, false) }

    describe "initialize" do
      it "sets instance variables" do
        expect(pkg_builder.detail_type).to eql(params["detail_type"])
        expect(pkg_builder.detail_params).to eql(detail_attributes)
      end
    end

    describe "build_detail" do
      it "builds detail" do
        pkg_detail = pkg_builder.build_detail
        expect(pkg_detail).to_not be nil
        expect(pkg_detail.brand).to eq(detail_attributes["brand"])
      end
    end
  end
