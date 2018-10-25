require 'rails_helper'

RSpec.describe Api::V1::AppointmentSlotPresetsController, type: :controller do
  let(:order_administrator) { create(:user, :order_administrator, :with_can_manage_settings )}
  let(:no_permission_user) { create :user }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:payload) { FactoryBot.build(:appointment_slot_preset, hours: 23, minutes: 0).attributes.except('id', 'updated_at', 'created_at') }
  let(:appt_slot) { create :appointment_slot_preset }


  describe "GET /appointment_slot_presets" do

    context 'When not logged in' do
      it "prevents reading default slots", :show_in_doc do
        get :index
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in as Supervisor' do
      before { generate_and_set_token(order_administrator) }

      it "returns 200", :show_in_doc do
        get :index
        expect(response.status).to eq(200)
      end

      it 'returns all preset slots' do
        5.times { FactoryBot.create :appointment_slot_preset }        
        get :index
        expect(parsed_body['appointment_slot_presets'].count).to eq(AppointmentSlotPreset.count)
      end
    end

    context 'When logged in without any rights' do
      before { generate_and_set_token(no_permission_user) }

      it "prevents reading default slots", :show_in_doc do
        get :index
        expect(response.status).to eq(403)
      end

    end

  end

  describe "POST /appointment_slot_presets" do

    context 'When not logged in' do
      it "denies creation of a default appointment slot" do
        post :create, appointment_slot_preset: payload
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in without permissions' do
      before { generate_and_set_token(no_permission_user) }
      it "denies creation of a default appointment slot" do
        post :create, appointment_slot_preset: payload
        expect(response.status).to eq(403)
      end
    end

    context 'When logged in as an order administrator' do
      before { generate_and_set_token(order_administrator) }

      it "allows the order administrator to create a default appointment slot" do
        post :create, appointment_slot_preset: payload
        expect(response.status).to eq(201)
        expect(parsed_body['appointment_slot_preset']['quota']).to eq(payload['quota'])
        expect(parsed_body['appointment_slot_preset']['hours']).to eq(payload['hours'])
        expect(parsed_body['appointment_slot_preset']['minutes']).to eq(payload['minutes'])
        expect(parsed_body['appointment_slot_preset']['day']).to eq(payload['day'])
      end
    end
  end

  describe "PUT /appointment_slot_presets/1" do
    context 'When not logged in' do
      it "denies update of an appointment slot preset" do
        put :update, id: appt_slot.id, appointment_slot_preset: payload
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in as a user without can_manage_settings permission' do
      before { generate_and_set_token(no_permission_user) }

      it "denies update of an appointment slot preset" do
        put :update, id: appt_slot.id, appointment_slot_preset: payload
        expect(response.status).to eq(403)
      end
    end

    context 'When logged in as a order administrator' do
      before { generate_and_set_token(order_administrator) }

      it "allows a supervisor to modify an appointment slot preset" do
        new_preset = FactoryBot.create(:appointment_slot_preset)
        put :update, id: new_preset.id, appointment_slot_preset: { day: 7 }
        expect(response.status).to eq(200)
        expect(parsed_body['appointment_slot_preset']['day']).to eq(7)
      end
    end
  end

  describe "DELETE /appointment_slot_presets/1" do
    context 'When not logged in' do
      it "denies destruction of an appointment slot preset" do
        put :destroy, id: appt_slot.id
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in as a user without can_manage_settings permission' do
      before { generate_and_set_token(no_permission_user) }

      it "denies destruction of an appointment slot preset" do
        put :destroy, id: appt_slot.id
        expect(response.status).to eq(403)
      end
    end

    context 'When logged in as a order administrator' do
      before { generate_and_set_token(order_administrator) }

      it "allows a supervisor to destroy an appointment slot preset" do
        id = appt_slot.id
        put :destroy, id: id
        expect(response.status).to eq(200)
        expect(AppointmentSlotPreset.find_by(id: id)).to eq(nil)
      end
    end
  end

end
