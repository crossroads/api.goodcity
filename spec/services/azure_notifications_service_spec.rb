require "rails_helper"

context AzureNotificationsService do

  let(:app_name) { DONOR_APP }
  let(:service) { AzureNotificationsService.new(app_name) }

  context "initialization" do
    context 'when app name is invalid' do
      let(:app_name) { 'unknown' }
      it { expect{ AzureNotificationsService.new(app_name) }.to raise_error(ArgumentError) }
    end
  end

  context "notification_title" do
    
    context "donor app" do
      let(:app_name) { DONOR_APP }
      context "in production" do
        before { allow(Rails.env).to receive("production?").and_return(true) }
        it { expect(service.send(:notification_title)).to eql("GoodCity") }
      end
      it { expect(service.send(:notification_title)).to eql("S. GoodCity") }
    end

    context "admin app" do
      let(:app_name) { ADMIN_APP }
      context "in production" do
        before { allow(Rails.env).to receive("production?").and_return(true) }
        it { expect(service.send(:notification_title)).to eql("GoodCity Admin") }
      end
      it { expect(service.send(:notification_title)).to eql("S. GoodCity Admin") }
    end

    context "stock app" do
      let(:app_name) { STOCK_APP}
      context "in production" do
        before { allow(Rails.env).to receive("production?").and_return(true) }
        it { expect(service.send(:notification_title)).to eql("GoodCity Stock") }
      end
      it { expect(service.send(:notification_title)).to eql("S. GoodCity Stock") }
    end

    context "browse app" do
      let(:app_name) { BROWSE_APP }
      context "in production" do
        before { allow(Rails.env).to receive("production?").and_return(true) }
        it { expect(service.send(:notification_title)).to eql("GoodCity Browse") }
      end
      it { expect(service.send(:notification_title)).to eql("S. GoodCity Browse") }
    end

  end
end
