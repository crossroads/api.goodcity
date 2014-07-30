require 'rails_helper'

RSpec.describe ApplicationController, :type => :controller do

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

end
