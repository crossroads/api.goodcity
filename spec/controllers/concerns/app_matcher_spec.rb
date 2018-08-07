require 'rails_helper'

class AppMatcherFakeController < ActionController::Base
  include AppMatcher
end

describe AppMatcherFakeController do

  context '#app_name' do

    before do
      request.headers["X-GOODCITY-APP-NAME"] = goodcity_app_name
    end
    
    context "donor app" do
      let(:goodcity_app_name) { 'app.goodcity' }
      it { expect(controller.app_name).to eql(DONOR_APP) }
    end

    context "admin app" do
      let(:goodcity_app_name) { 'admin.goodcity' }
      it { expect(controller.app_name).to eql(ADMIN_APP) }
    end

    context "stock app" do
      let(:goodcity_app_name) { 'stock.goodcity' }
      it { expect(controller.app_name).to eql(STOCK_APP) }
    end

    context "browse app" do
      let(:goodcity_app_name) { 'browse.goodcity' }
      it { expect(controller.app_name).to eql(BROWSE_APP) }
    end

    context "stockit app (special case)" do
      let(:goodcity_app_name) { 'stockit.goodcity' }
      it { expect(controller.app_name).to eql(STOCKIT_APP) }
    end

    context "unknown app" do
      let(:goodcity_app_name) { 'unknown.goodcity' }
      it { expect(controller.app_name).to eql(nil) }
    end

    context "nil app" do
      let(:goodcity_app_name) { '' }
      it { expect(controller.app_name).to eql(nil) }
    end

  end

  context "is_admin_app?" do
    it do
      expect(controller).to receive(:app_name).and_return(ADMIN_APP)
      expect(controller.is_admin_app?).to eql(true)
    end
    it do
      expect(controller).to receive(:app_name).and_return(DONOR_APP)
      expect(controller.is_admin_app?).to eql(false)
    end
  end

  context "is_stock_app?" do
    it do
      expect(controller).to receive(:app_name).and_return(STOCK_APP)
      expect(controller.is_stock_app?).to eql(true)
    end
    it do
      expect(controller).to receive(:app_name).and_return(DONOR_APP)
      expect(controller.is_stock_app?).to eql(false)
    end
  end

  context "is_browse_app?" do
    it do
      expect(controller).to receive(:app_name).and_return(BROWSE_APP)
      expect(controller.is_browse_app?).to eql(true)
    end
    it do
      expect(controller).to receive(:app_name).and_return(DONOR_APP)
      expect(controller.is_browse_app?).to eql(false)
    end
  end

  context "is_stockit_request?" do
    it do
      expect(controller).to receive(:app_name).and_return(STOCKIT_APP)
      expect(controller.is_stockit_request?).to eql(true)
    end
    it do
      expect(controller).to receive(:app_name).and_return(DONOR_APP)
      expect(controller.is_stockit_request?).to eql(false)
    end
  end

end