require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do

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

  context 'token header' do
    it 'has validate authorization header set' do
      request.headers['Authorization'] = "Bearer  s2xtqb5mspzg4rq7"
      expect(controller.send(:token_header)).to eq("s2xtqb5mspzg4rq7")
    end
    it 'had empty authorization header' do
      request.headers['Authorization'] = "Bearer   "
      expect(controller.send(:token_header)).to eq("undefined")
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
