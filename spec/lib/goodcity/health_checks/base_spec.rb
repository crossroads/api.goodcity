require 'rails_helper'
require 'goodcity/health_checks/base'

context Goodcity::HealthChecks::Base do

  subject { described_class.new }

  context "initialization" do
    it { expect(subject.status).to eql("PENDING") }
    it { expect(subject.message).to eql("") }
  end

  context "run" do
    it { expect{subject.run}.to raise_error(NotImplementedError) }
  end

  context "name" do
    it { expect(subject.name).to eql("Base") }
  end

  context "pass" do
    before{ subject.pass! }
    it { expect(subject.status).to eql("PASSED") }
    it { expect(subject.passed?).to eql(true) }
    it { expect(subject.failed?).to eql(false) }
  end

  context "fail" do
    before{ subject.fail! }
    it { expect(subject.status).to eql("FAILED") }
    it { expect(subject.passed?).to eql(false) }
    it { expect(subject.failed?).to eql(true) }
  end

  context "fail_with_message!" do
    before{ subject.fail_with_message!("Broken") }
    it { expect(subject.status).to eql("FAILED" ) }
    it { expect(subject.message).to eql("Broken") }
  end

  context "subclass" do

    class CheckOne < Goodcity::HealthChecks::Base
      desc "Check One"
      def run; end
    end
    class CheckTwo < Goodcity::HealthChecks::Base
      desc "Check Two"
      def run; end
    end

    context "desc be set per class instance" do
      it { expect(CheckOne.new.desc).to eql("Check One") }
      it { expect(CheckTwo.new.desc).to eql("Check Two") }
      it { expect{CheckTwo.new.run}.to_not raise_error }
    end
  end

end
