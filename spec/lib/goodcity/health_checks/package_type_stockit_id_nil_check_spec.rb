require 'rails_helper' # needed to configure transaction rollback
require 'goodcity/health_checks/package_type_stockit_id_nil_check'

context Goodcity::HealthChecks::PackageTypeStockitIdNilCheck do

  subject { described_class.new }

  it { expect(subject.desc).to eql("PackageTypes should contain a stockit_id reference.") }

  context "passes" do
    before do
      create :base_package_type, stockit_id: 123
      subject.run
    end
    it { expect(subject.passed?).to eql(true) }
  end

  context "fails" do
    before do
      create :base_package_type, stockit_id: nil
      subject.run
    end
    it { expect(subject.passed?).to eql(false) }
    it { expect(subject.message).to include("GoodCity PackageTypes with nil stockit_id") }
  end

end
