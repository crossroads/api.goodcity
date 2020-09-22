require 'rails_helper'

RSpec.describe Api::V2::ApiController, type: :controller do
  let(:user) { create :user }
  let(:supervisor_role) { create :role, name: 'Supervisor', level: 15 }
  let(:order_administrator_role) { create :role, name: 'Order administrator', level: 10 }

  subject { JSON.parse(response.body) }

  before do
    supervisor_role.grant(user)
    order_administrator_role.grant(user)
  end

  describe "Current role resolution" do    
    context "when there is no logged in user" do
      it "sets the current role to nil" do
        expect(@controller.current_role).to be_nil
      end
    end

    context "when there is a logged in user" do
      before { generate_and_set_token(user) }

      it "defaults the role to the highest level" do
        expect(@controller.current_role).to eq(supervisor_role)
      end

      context "and the user specifies a role in the headers" do
        before { request.headers['X-GOODCITY-ROLE'] = 'order_administrator' }

        it "uses the specified role" do
          expect(@controller.current_role).to eq(order_administrator_role)
        end
      end

      context "and the user specifies a role he/she is not entitled to" do
        before { request.headers['X-GOODCITY-ROLE'] = 'system' }

        it "denies access" do
          expect { @controller.current_role }.to raise_error(Goodcity::AccessDeniedError)
        end
      end

      context "and the user specifies the 'user' role" do
        before { request.headers['X-GOODCITY-ROLE'] = 'user' }

        it "returns a null role with no permissions" do
          expect(@controller.current_role).not_to be_nil
          expect(@controller.current_role.name).to eq(Role.null_role.name)
          expect(@controller.current_role.permissions).to eq([])
        end

        it "returns a null role which cannot be persisted" do
          expect(@controller.current_role).not_to be_nil
          expect(@controller.current_role.name).to eq(Role.null_role.name)
          expect { @controller.current_role.save }.to raise_error(RuntimeError)
        end
      end
    end
  end

  context "handling ActiveRecord::RecordNotFound exceptions" do
    before { generate_and_set_token }

    controller do
      def index
        raise ActiveRecord::RecordNotFound.new('Oh noes !')
      end
    end

    it do
      get :index
      expect(response.status).to eq(404)
      expect(subject["error"]).to eql("Oh noes !")
      expect(subject["status"]).to eql(404)
      expect(subject["type"]).to eql("NotFoundError")
    end

  end

  context "handling CanCan::AccessDenied exceptions" do
    before { generate_and_set_token }

    controller do
      def index
        raise CanCan::AccessDenied
      end
    end

    it do
      get :index, format: 'json'
      expect(response.status).to eq(403)
      expect(subject["error"]).to eql("Access Denied")
      expect(subject["status"]).to eql(403)
      expect(subject["type"]).to eql("AccessDeniedError")
    end

  end

  context "handling Apipie::ParamInvalid exceptions" do
    before { generate_and_set_token }

    let(:error_msg) { "Invalid parameter 'language' value \"test\": Must be one of: en, zh-tw." }

    controller do
      def index
        raise Apipie::ParamInvalid.new("language", "test", "Must be one of: en, zh-tw.")
      end
    end

    it do
      get :index
      expect(response.status).to eq(422)
      expect(subject["error"]).to eql("Invalid parameter 'language' value \"test\": Must be one of: en, zh-tw.")
      expect(subject["status"]).to eql(422)
      expect(subject["type"]).to eql("InvalidParamsError")
    end
  end

  context "per_page" do
    before { generate_and_set_token }

    subject { controller.per_page }

    before(:each) do
      controller.params[:per_page] = per_page
    end

    context "20 per page" do
      let(:per_page) { '20' }
      it { expect(subject).to eql(20) }
    end

    context "30 per_page (limit is 50)" do
      let(:per_page) { '60' }
      it { expect(subject).to eql(50) }
    end

    context "nil per_page" do
      let(:per_page) { nil }
      it { expect(subject).to eql(25) }
    end

    context "blank per_page" do
      let(:per_page) { '' }
      it { expect(subject).to eql(25) }
    end

    context "blah per_page" do
      let(:per_page) { 'blah' }
      it { expect(subject).to eql(25) }
    end
  end
end
