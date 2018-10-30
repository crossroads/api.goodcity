require 'rails_helper'

RSpec.describe Api::V1::AppointmentSlotsController, type: :controller do
  let(:order_administrator) { create(:user, :order_administrator, :with_can_manage_settings )}
  let(:no_permission_user) { create :user }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET /appointment_slots" do

    context 'When not logged in' do
      it "prevents reading slots", :show_in_doc do
        get :index
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in as Supervisor' do
      before { 
        # Create presets
        (1..7).each { |i| FactoryBot.create :appointment_slot_preset, hours: 10, minutes: 30, day: i }
        generate_and_set_token(order_administrator) 
      }

      it "returns 200", :show_in_doc do
        get :index
        expect(response.status).to eq(200)
      end

      it 'returns upcoming spectial slots' do
        now = DateTime.now
        FactoryBot.create :appointment_slot, timestamp: now
        FactoryBot.create :appointment_slot, timestamp: now + 1
        FactoryBot.create :appointment_slot, timestamp: now + 2
        FactoryBot.create :appointment_slot, timestamp: now - 30  
        get :index
        expect(parsed_body['appointment_slots'].count).to eq(3)
        saved_timestamp = DateTime.parse(parsed_body['appointment_slots'][0]['timestamp']);
        expect(saved_timestamp.utc).to eq(now.utc);
      end

      it 'returns slots aggregated by date (/appointment_slots/calendar)' do
        FactoryBot.create :appointment_slot, timestamp: DateTime.parse('29th Oct 2018 16:30:00+08:00')  
        FactoryBot.create :appointment_slot, timestamp: DateTime.parse('29th Oct 2018 14:00:00+08:00')
        FactoryBot.create :appointment_slot, timestamp: DateTime.parse('31st Oct 2018 10:00:00+08:00')   
        get :calendar, from: '2018-10-16', to: '2018-10-31'
        expect(parsed_body.count).to eq(16)

        # Check an auto-generated slot
        oct_16th = parsed_body[0];
        expect(oct_16th['date']).to eq("2018-10-16")
        expect(oct_16th['slots'].count).to eq(1)
        expect(oct_16th['slots'][0]['timestamp']).to eq("2018-10-16T10:30:00.000+08:00")
        # Check a special date
        oct_29th = parsed_body[13];
        expect(oct_29th['date']).to eq("2018-10-29")
        expect(oct_29th['slots'].count).to eq(2)
        expect(oct_29th['slots'][0]['timestamp']).to eq("2018-10-29T14:00:00.000+08:00")
      end
    end

    context 'When logged in without any rights' do
      before { generate_and_set_token(no_permission_user) }

      it "prevents reading slots", :show_in_doc do
        get :index
        expect(response.status).to eq(403)
      end

    end

  end

  describe "POST /appointment_slots" do
    let!(:payload) { {quota: 5, timestamp: DateTime.now.to_s} }

    context 'When not logged in' do
      it "denies creation of an appointment slot" do
        post :create, appointment_slot: payload
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in without permissions' do
      before { generate_and_set_token(no_permission_user) }
      it "denies creation of an appointment slot" do
        post :create, appointment_slot: payload
        expect(response.status).to eq(403)
      end
    end

    context 'When logged in as an order administrator' do
      before { generate_and_set_token(order_administrator) }

      it "allows the order administrator to create an appointment slot" do
        t = DateTime.now
        post :create, appointment_slot: {quota: 5, timestamp: t.to_s}
        expect(response.status).to eq(201)
        expect(DateTime.parse(parsed_body['appointment_slot']['timestamp']).utc.to_s(:db)).to eq(t.utc.to_s(:db))
        expect(parsed_body['appointment_slot']['quota']).to eq(5)
      end

      it "should update an appointment slot if it exists already" do
        t = DateTime.parse('29th Oct 2018 14:00:00+08:00')
        existing_slot = FactoryBot.create :appointment_slot, timestamp: t, quota: 10
        expect(AppointmentSlot.count).to eq(1)

        post :create, appointment_slot: {quota: 5, timestamp: t.to_s}
        expect(response.status).to eq(201)
        expect(AppointmentSlot.count).to eq(1)
        expect(AppointmentSlot.first.timestamp).to eq(t)
        expect(AppointmentSlot.first.quota).to eq(5)
        expect(AppointmentSlot.first.id).to eq(existing_slot.id)
        expect(parsed_body['appointment_slot']['id']).to eq(existing_slot.id)
      end
    end
  end

  describe "DELETE /appointment_slots/1" do
    let!(:appt_slot) { FactoryBot.create :appointment_slot, timestamp: DateTime.now, quota: 10 }

    context 'When not logged in' do
      it "denies destruction of an appointment slot" do
        put :destroy, id: appt_slot.id
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in as a user without can_manage_settings permission' do
      before { generate_and_set_token(no_permission_user) }

      it "denies destruction of an appointment slot" do
        put :destroy, id: appt_slot.id
        expect(response.status).to eq(403)
      end
    end

    context 'When logged in as a order administrator' do
      before { generate_and_set_token(order_administrator) }

      it "allows a supervisor to destroy an appointment slot" do
        id = appt_slot.id
        put :destroy, id: id
        expect(response.status).to eq(200)
        expect(AppointmentSlot.find_by(id: id)).to eq(nil)
      end
    end
  end

end
