require "rails_helper"

RSpec.describe Api::V1::PrintersUsersController, type: :controller do
  let(:supervisor) { create(:user, :with_supervisor_role, :with_can_manage_printers_permission)}
  let(:reviewer) { create(:user, :with_reviewer_role)}
  let(:stock_administrator) { create(:user, :with_stock_administrator_role, :with_can_manage_printers_permission )}
  let(:order_administrator) { create(:user, :with_order_administrator_role, :with_can_manage_printers_permission)}
  let(:charity_user) { create :user, :charity }
  let(:printer) {create :printer}
  let(:printers_user) {create :printers_user}
  let(:printers_supervisor_params) { FactoryBot.attributes_for(:printers_user, user_id: supervisor.id, printer_id: printer.id, tag: 'stock') }
  let(:printers_stock_administrator_params) { FactoryBot.attributes_for(:printers_user, user_id: stock_administrator.id, printer_id: printer.id, tag: 'stock') }
  let(:printers_order_administrator_params) { FactoryBot.attributes_for(:printers_user, user_id: order_administrator.id, printer_id: printer.id, tag: 'stock') }
  let(:printers_reviewer_params) { FactoryBot.attributes_for(:printers_user, user_id: reviewer.id, printer_id: printer.id, tag: 'stock') }
  let(:printers_charity_user_params) { FactoryBot.attributes_for(:printers_user, user_id: charity_user.id, printer_id: printer.id, tag: 'stock') }


  describe "POST printers_users" do
    context 'With Supervisor role' do
      before { generate_and_set_token(supervisor) }

      it "returns 201", :show_in_doc do
        post :create, params: { printers_users: printers_supervisor_params }
        expect(response.status).to eq(201)
      end
    end

    context 'With stock administrator role' do
      before { generate_and_set_token(stock_administrator) }

      it "returns 201", :show_in_doc do
        post :create, params: { printers_users: printers_stock_administrator_params }
        expect(response.status).to eq(201)
      end
    end

    context 'With Order administrator role' do
      before { generate_and_set_token(stock_administrator) }

      it "returns 201", :show_in_doc do
        post :create, params: { printers_users: printers_order_administrator_params }
        expect(response.status).to eq(201)
      end
    end

    context 'With Charity User role' do
      before { generate_and_set_token(charity_user) }

      it "returns 403", :show_in_doc do
        post :create, params: { printers_users: printers_charity_user_params }
        expect(response.status).to eq(403)
      end
    end

    context 'With Reviewer role' do
      before { generate_and_set_token(reviewer) }

      it "returns 403", :show_in_doc do
        post :create, params: { printers_users: printers_reviewer_params }
        expect(response.status).to eq(403)
      end
    end
  end

  describe "PUT printers_users/1" do
    context 'With Supervisor role' do
      before { generate_and_set_token(supervisor) }

      it "returns 200", :show_in_doc do
        params = { printer_id: printer.id }
        put :update, params: { id: printers_user.id, printers_users: params }
        expect(response.status).to eq(200)
        expect(printers_user.reload.printer_id).to eq(printers_user.reload.printer_id)
      end
    end

    context 'With Reviewer role' do
      let(:reviewer) { create(:user, :with_reviewer_role, :with_can_update_my_printers_permission)}
      let(:update_printers_user) {create :printers_user, user: reviewer}
      before { generate_and_set_token(reviewer) }

      it "returns 200", :show_in_doc do
        params = { printer_id: printer.id }
        put :update, params: { id: update_printers_user.id, printers_users: params }
        expect(response.status).to eq(200)
        expect(update_printers_user.reload.printer_id).to eq(printer.id)
      end
    end

    context 'With Order Fulfilment role' do
      let(:order_fulfilment) { create(:user, :with_order_fulfilment_role, :with_can_update_my_printers_permission) }
      let(:update_printers_user) {create :printers_user, user: order_fulfilment}
      before { generate_and_set_token(order_fulfilment) }

      it "returns 200", :show_in_doc do
        params = { printer_id: printer.id }
        put :update, params: { id: update_printers_user.id, printers_users: params }
        expect(response.status).to eq(200)
        expect(update_printers_user.reload.printer_id).to eq(printer.id)
      end
    end

    context 'With Stock Fulfilment role' do
      let(:stock_fulfilment) { create(:user, :with_stock_fulfilment_role, :with_can_update_my_printers_permission) }
      let(:update_printers_user) {create :printers_user, user: stock_fulfilment}
      before { generate_and_set_token(stock_fulfilment) }

      it "returns 200", :show_in_doc do
        params = { printer_id: printer.id }
        put :update, params: { id: update_printers_user.id, printers_users: params }
        expect(response.status).to eq(200)
        expect(update_printers_user.reload.printer_id).to eq(printer.id)
      end
    end

    context 'With Charity User role' do
      before { generate_and_set_token(charity_user) }

      it "returns 403", :show_in_doc do
        params = { printer_id: printer.id }
        put :update, params: { id: printers_user.id, printers_users: params }
        expect(response.status).to eq(403)
      end
    end
  end
end
