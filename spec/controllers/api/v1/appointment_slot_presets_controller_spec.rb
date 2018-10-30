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

      it "allows the order administrator to create an appointment slot preset" do
        post :create, appointment_slot_preset: payload
        expect(response.status).to eq(201)
        expect(parsed_body['appointment_slot_preset']['quota']).to eq(payload['quota'])
        expect(parsed_body['appointment_slot_preset']['hours']).to eq(payload['hours'])
        expect(parsed_body['appointment_slot_preset']['minutes']).to eq(payload['minutes'])
        expect(parsed_body['appointment_slot_preset']['day']).to eq(payload['day'])
      end

      it "should update an appointment slot preset if it exists already" do
        existing_preset = FactoryBot.create :appointment_slot_preset, day: 1, hours: 14, minutes: 30, quota: 3
        expect(AppointmentSlotPreset.count).to eq(1)

        post :create, appointment_slot_preset: { day: 1, hours: 14, minutes: 30, quota: 10 }
        expect(response.status).to eq(201)
        expect(AppointmentSlotPreset.count).to eq(1)
        expect(AppointmentSlotPreset.first.day).to eq(1)
        expect(AppointmentSlotPreset.first.hours).to eq(14)
        expect(AppointmentSlotPreset.first.minutes).to eq(30)
        expect(AppointmentSlotPreset.first.quota).to eq(10)
        expect(AppointmentSlotPreset.first.id).to eq(existing_preset.id)
        expect(parsed_body['appointment_slot_preset']['id']).to eq(existing_preset.id)
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
