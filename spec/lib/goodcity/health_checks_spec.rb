require 'goodcity/health_checks'

context Goodcity::HealthChecks do

  subject { described_class.new }
  let(:check_one) { CheckOne.new }

  class CheckOne < Goodcity::HealthChecks::Base
    desc "Check One"
    def run; end
  end

  context "initialization" do
    it { expect(subject.instance_variable_get("@checks").class).to eql(Array) }
  end

  context "enumeration methods" do
    before { subject.instance_variable_set("@checks", [check_one]) }
    
    context "run" do
      it do
        expect(check_one).to receive(:run)
        subject.run
      end
    end

    context "list_checks" do
      it do
        expect(check_one).to receive(:name)
        expect(check_one).to receive(:desc)
        subject.list_checks
      end
    end

    context "report" do
      it do
        expect(check_one).to receive(:status)
        expect(check_one).to receive(:name)
        subject.report(check_one)
      end
    end
  end

end