require "rails_helper"

RSpec.describe Api::V1::PrintersUsersController, type: :controller do
  let(:supervisor) { create(:user, :supervisor, :with_can_access_printers_permission)}
  let(:reviewer) { create(:user, :reviewer, :with_can_access_printers_permission)}
  let(:charity_user) { create :user, :charity }
  let(:printer) {create :printer}
  let(:printers_user) {create :printers_user}
  let(:printers_supervisor_params) { FactoryBot.attributes_for(:printers_user, user_id: supervisor.id, printer_id: printer.id, tag: 'stock') }
  let(:printers_reviewer_params) { FactoryBot.attributes_for(:printers_user, user_id: reviewer.id, printer_id: printer.id, tag: 'admin') }
  let(:printers_charity_user_params) { FactoryBot.attributes_for(:printers_user, user_id: charity_user.id, printer_id: printer.id, tag: 'stock') }


  describe "POST printers_users" do
    context 'With Supervisor role' do
      before { generate_and_set_token(supervisor) }

      it "returns 201", :show_in_doc do
        post :create, printers_users: printers_supervisor_params
        expect(response.status).to eq(201)
      end
    end

    context 'With Reviewer role' do
      before { generate_and_set_token(reviewer) }

      it "returns 201", :show_in_doc do
        post :create, printers_users: printers_reviewer_params
        expect(response.status).to eq(201)
      end
    end

    context 'With Charity User role' do
      before { generate_and_set_token(charity_user) }

      it "returns 403", :show_in_doc do
        post :create, printers_users: printers_charity_user_params
        expect(response.status).to eq(403)
      end
    end
  end

  describe "PUT printers_users/1" do
    context 'With Supervisor role' do
      before { generate_and_set_token(supervisor) }

      it "returns 201", :show_in_doc do
        params = { printer_id: printer.id }
        put :update, id: printers_user.id, printers_users: params
        expect(response.status).to eq(200)
        expect(printers_user.reload.printer_id).to eq(printer.id)
      end
    end

    context 'With Reviewer role' do
      before { generate_and_set_token(reviewer) }

      it "returns 201", :show_in_doc do
        params = { printer_id: printer.id }
        put :update, id: printers_user.id, printers_users: params
        expect(response.status).to eq(200)
        expect(printers_user.reload.printer_id).to eq(printer.id)
      end
    end

    context 'With Charity User role' do
      before { generate_and_set_token(charity_user) }

      it "returns 403", :show_in_doc do
        params = { printer_id: printer.id }
        put :update, id: printers_user.id, printers_users: params
        expect(response.status).to eq(403)
      end
    end
  end
end
