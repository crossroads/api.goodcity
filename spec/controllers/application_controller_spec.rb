require 'rails_helper'

RSpec.describe ApplicationController, :type => :controller do

  context "set_locale" do

    it "should set locale to zh-tw" do
      I18n.locale = 'en'
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'zh-tw'
      HttpAcceptLanguage::Middleware.new(lambda {|env| env }).call(request.env)
      controller.send(:set_locale)
      expect(I18n.locale).to eql(:'zh-tw')
    end

    it "should set locale to en" do
      I18n.locale = 'zh-tw'
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'en'
      HttpAcceptLanguage::Middleware.new(lambda {|env| env }).call(request.env)
      controller.send(:set_locale)
      expect(I18n.locale).to eql(:en)
    end

  end

end
