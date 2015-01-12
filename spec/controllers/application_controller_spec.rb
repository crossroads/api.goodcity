require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe "ApplicationController" do

    context "set_locale" do
      it "should set locale to zh-tw" do
        set_locale("zh-tw")
        controller.send(:set_locale)
        expect(I18n.locale).to eql(:'zh-tw')
      end

      it "should set locale to en" do
        set_locale("en", "zh-tw")
        controller.send(:set_locale)
        expect(I18n.locale).to eql(:en)
      end

      it "should set locale to en when unknown language" do
        set_locale("za")
        controller.send(:set_locale)
        expect(I18n.locale).to eql(:en)
      end

    end

    context "current_user" do

      let(:data)  { [{ "user_id" => "1" }] }
      let(:token) { double(data: data) }
      let(:user) { build :user }
      before { allow(controller).to receive(:token).and_return(token) }

      context "with valid token" do
        before { expect(token).to receive("valid?").and_return(true) }
        it "should find the user by id" do
          expect(token).to receive("data").and_return(data)
          expect(User).to receive(:find_by_id).with("1").and_return(user)
          expect( controller.send(:current_user) ).to eql(user)
        end
        it "should not find the user_id" do
          expect(token).to receive("data").and_return([{}])
          expect(User).to_not receive(:find_by_id)
          expect( controller.send(:current_user) ).to eql(nil)
        end
      end

      context "with invalid token" do
        before { expect(token).to receive("valid?").and_return(false) }
        it "should return nil if token invalid" do
          expect(User).to_not receive(:find_by_id)
          expect( controller.send(:current_user) ).to eql(nil)
        end
      end

    end

  end
end
