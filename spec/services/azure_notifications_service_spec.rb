require "rails_helper"

describe AzureNotificationsService do

  let(:is_admin_app) { false }
  let(:service) { AzureNotificationsService.new(is_admin_app) }

  describe "app_namespace" do
    describe "should return donor" do
      it { expect(service.send(:app_namespace)).to eql("donor") }
    end
    describe "should return admin" do
      let(:is_admin_app) { true }
      it { expect(service.send(:app_namespace)).to eql("admin") }
    end
  end

  describe "notification_title" do
    describe "should return GoodCity" do
      before { allow(Rails.env).to receive("production?").and_return(true) }
      it { expect(service.send(:notification_title)).to eql("GoodCity") }
    end
    describe "should return GoodCity Admin" do
      before { allow(Rails.env).to receive("production?").and_return(true) }
      let(:is_admin_app) { true }
      it { expect(service.send(:notification_title)).to eql("GoodCity Admin") }
    end
    describe "should return S. GoodCity" do
      before { allow(Rails.env).to receive("production?").and_return(false) }
      it { expect(service.send(:notification_title)).to eql("S. GoodCity") }
    end
    describe "should return S. GoodCity Admin" do
      before { allow(Rails.env).to receive("production?").and_return(false) }
      let(:is_admin_app) { true }
      it { expect(service.send(:notification_title)).to eql("S. GoodCity Admin") }
    end
  end

end
