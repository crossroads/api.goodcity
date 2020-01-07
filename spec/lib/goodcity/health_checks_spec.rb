require 'goodcity/health_checks'

context Goodcity::HealthChecks do

  subject { described_class }
  let(:check_one) { CheckOne }

  class CheckOne < Goodcity::HealthChecks::Base
    desc "Check One"
    def run; end
  end

  context "initialization" do
    it { expect(subject.checks.class).to eql(Array) }
  end

  context "enumeration methods" do
    before { subject.checks = [check_one] }
    
    context "run_all" do
      it do
        expect_any_instance_of(check_one).to receive(:run)
        expect_any_instance_of(check_one).to receive(:report)
        subject.run_all
      end
    end

    context "list_checks" do
      it do
        expect(check_one).to receive(:name)
        expect(check_one).to receive(:desc)
        subject.list_checks
      end
    end

    context "register_check" do
      it do
        subject.register_check(CheckOne)
        expect(subject.checks).to include(CheckOne)
      end
    end
  end

end