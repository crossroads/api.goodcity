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

  context "fcm_platform_xml" do
    let(:handle) { "registration-token" }
    let(:tags) { ["user_1"] }
    let(:xml) { service.send(:fcm_platform_xml, handle, tags) }
    let(:template) { xml.match(/<!\[CDATA\[(.*)\]\]>/m)[1] }
    let(:payload) { JSON.parse(template) }

    it "includes a notification block for system notifications" do
      notification = payload.fetch("message").fetch("notification")

      expect(notification).to include(
        "title" => "S. GoodCity",
        "body" => "$(message)"
      )
    end

    it "keeps the data payload used by the app" do
      data = payload.fetch("message").fetch("data")

      expect(data).to include(
        "title" => "S. GoodCity",
        "message" => "$(message)",
        "category" => "$(category)",
        "offer_id" => "$(offer_id)",
        "message_id" => "$(message_id)"
      )
    end
  end
end
