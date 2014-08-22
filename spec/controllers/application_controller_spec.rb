require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe "ApplicationController" do

    context "set_locale" do
      it "should set locale to zh-tw" do
        set_locale('zh-tw')
        controller.send(:set_locale)
        expect(I18n.locale).to eql(:'zh-tw')
      end

      it "should set locale to en" do
        set_locale('en', 'zh-tw')
        controller.send(:set_locale)
        expect(I18n.locale).to eql(:en)
      end
    end

    context 'verify warden' do
      it 'warden object' do
        expect(controller.send(:warden)).to eq(request.env["warden"])
      end

      it 'env[warden_options] object' do
        expect(controller.send(:warden_options)).to eq(request.env["warden_options"])
      end
    end

  end
end
