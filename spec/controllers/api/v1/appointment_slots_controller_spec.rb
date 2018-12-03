require 'rails_helper'

RSpec.describe Api::V1::AppointmentSlotsController, type: :controller do
  let(:order_administrator) { create(:user, :order_administrator, :with_can_manage_settings )}
  let(:no_permission_user) { create :user }
  let(:parsed_body) { JSON.parse(response.body) }

  before {
    FactoryBot.generate(:booking_types).values.each { |btype|
      FactoryBot.create :booking_type, identifier: btype[:identifier]
    }
  }

  def now
    DateTime.now.change(sec: 0, usec: 0)
  end

  def assert_datetime_equals(dt1, dt2)
    dt1 = DateTime.parse(dt1) if dt1.is_a?(String)
    dt2 = DateTime.parse(dt2) if dt2.is_a?(String)
    expect(dt1.utc.to_s).to eq(dt2.utc.to_s)
  end

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
        ts = now()
        FactoryBot.create :appointment_slot, timestamp: ts
        FactoryBot.create :appointment_slot, timestamp: ts + 1
        FactoryBot.create :appointment_slot, timestamp: ts + 2
        FactoryBot.create :appointment_slot, timestamp: ts - 30
        get :index
        expect(parsed_body['appointment_slots'].count).to eq(3)
        assert_datetime_equals(parsed_body['appointment_slots'][0]['timestamp'], ts)
      end

      it 'returns slots aggregated by date (/calendar) - except those with 0 quota' do
        FactoryBot.create :appointment_slot, timestamp: DateTime.parse('29th Oct 2018 16:30:00+08:00')
        FactoryBot.create :appointment_slot, timestamp: DateTime.parse('29th Oct 2018 14:00:00+08:00')
        FactoryBot.create :appointment_slot, timestamp: DateTime.parse('29th Oct 2018 14:00:00+08:00'), quota: 0
        FactoryBot.create :appointment_slot, timestamp: DateTime.parse('31st Oct 2018 10:00:00+08:00')
        get :calendar, from: '2018-10-16', to: '2018-10-31'
        results = parsed_body['appointment_calendar_dates']
        expect(results.count).to eq(16)

        # Check an auto-generated slot
        oct_16th = results[0];
        expect(oct_16th['date']).to eq("2018-10-16")
        expect(oct_16th['slots'].count).to eq(1)
        expect(oct_16th['slots'][0]['timestamp']).to eq("2018-10-16T10:30:00.000+08:00")
        # Check a special date
        oct_29th = results[13];
        expect(oct_29th['date']).to eq("2018-10-29")
        expect(oct_29th['slots'].count).to eq(2)
        expect(oct_29th['slots'][0]['timestamp']).to eq("2018-10-29T14:00:00.000+08:00")
      end

      it 'specifies the number of remaining slots (/calendar)' do
        (1..5).each { |i| FactoryBot.create :order_transport, scheduled_at: Date.parse('29-10-2018'), timeslot: '10:30AM-11:30PM', booking_type: BookingType.appointment }
        (1..3).each { |i| FactoryBot.create :order_transport, scheduled_at: Date.parse('30-10-2018'), timeslot: '10:30AM-11:30PM', booking_type: BookingType.appointment }
        (1..5).each { |i| FactoryBot.create :order_transport, scheduled_at: Date.parse('30-10-2018'), timeslot: '2PM-3PM', booking_type: BookingType.appointment }
        FactoryBot.create :appointment_slot, timestamp: DateTime.parse('29th Oct 2018 10:30:00+08:00'), quota: 5 # Monday
        FactoryBot.create :appointment_slot, timestamp: DateTime.parse('30th Oct 2018 10:30:00+08:00'), quota: 5 # Tuesday
        FactoryBot.create :appointment_slot, timestamp: DateTime.parse('30th Oct 2018 14:00:00+08:00'), quota: 5 # Tuesday

        get :calendar, from: '2018-10-29', to: '2018-10-30'
        results = parsed_body['appointment_calendar_dates']
        expect(results.count).to eq(2)

        oct_29th = results[0];
        expect(oct_29th['date']).to eq("2018-10-29")
        expect(oct_29th['isClosed']).to eq(true)
        expect(oct_29th['slots'].count).to eq(1)
        expect(oct_29th['slots'][0]['timestamp']).to eq("2018-10-29T10:30:00.000+08:00")
        expect(oct_29th['slots'][0]['isClosed']).to eq(true)
        expect(oct_29th['slots'][0]['remaining']).to eq(0)

        oct_30th = results[1];
        expect(oct_30th['date']).to eq("2018-10-30")
        expect(oct_30th['isClosed']).to eq(false)
        expect(oct_30th['slots'].count).to eq(2)
        expect(oct_30th['slots'][0]['timestamp']).to eq("2018-10-30T10:30:00.000+08:00")
        expect(oct_30th['slots'][0]['isClosed']).to eq(false)
        expect(oct_30th['slots'][0]['remaining']).to eq(2)
        expect(oct_30th['slots'][1]['timestamp']).to eq("2018-10-30T14:00:00.000+08:00")
        expect(oct_30th['slots'][1]['isClosed']).to eq(true)
        expect(oct_30th['slots'][1]['remaining']).to eq(0)
      end

      it 'should show public holidays as blocked' do
        create(:holiday, holiday: DateTime.parse('17th Mar 2018 00:00:00'), name: "Saint Patrick's day")

        get :calendar, from: '2018-03-17', to: '2018-03-17'
        results = parsed_body['appointment_calendar_dates']
        expect(results.count).to eq(1)

        mar_17th = results[0];
        expect(mar_17th['date']).to eq("2018-03-17")
        expect(mar_17th['isClosed']).to eq(true)
        expect(mar_17th['slots'].count).to eq(0)
      end

      it 'should show public holidays as available only if a special slot has been set for that day' do
        create(:holiday, holiday: DateTime.parse('17th Mar 2018 00:00:00'), name: "Saint Patrick's day")
        FactoryBot.create :appointment_slot, timestamp: DateTime.parse('17th Mar 2018 14:00:00+08:00'), quota: 5

        get :calendar, from: '2018-03-17', to: '2018-03-17'
        results = parsed_body['appointment_calendar_dates']
        expect(results.count).to eq(1)

        mar_17th = results[0];
        expect(mar_17th['date']).to eq("2018-03-17")
        expect(mar_17th['isClosed']).to eq(false)
        expect(mar_17th['slots'].count).to eq(1)
        expect(mar_17th['slots'][0]['timestamp']).to eq("2018-03-17T14:00:00.000+08:00")
        expect(mar_17th['slots'][0]['isClosed']).to eq(false)
        expect(mar_17th['slots'][0]['remaining']).to eq(5)
      end

      it 'limits the number of slots returned -> a maximum of 2 years worth of data should be returned' do
        get :calendar, from: '2018-10-16', to: '2100-10-31'
        expect(parsed_body['appointment_calendar_dates'].count).to eq(732)
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
    let!(:payload) { {quota: 5, timestamp: now.to_s} }

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
        t = now
        post :create, appointment_slot: {quota: 5, timestamp: t.to_s}
        expect(response.status).to eq(201)
        expect(parsed_body['appointment_slot']['quota']).to eq(5)
        assert_datetime_equals(parsed_body['appointment_slot']['timestamp'], t)
      end

      it "fails to create an appointment slot if the slot is already taken" do
        ts = now
        FactoryBot.create :appointment_slot, timestamp: ts
        post :create, appointment_slot: { quota: 5, timestamp: ts.to_s }
        expect(response.status).to eq(422)
      end
    end
  end

  describe "PUT /appointment_slot/1" do
    let!(:appt_slot) { FactoryBot.create :appointment_slot, timestamp: now, quota: 10 }

    context 'When not logged in' do
      it "denies update of an appointment slot" do
        put :update, id: appt_slot.id, appointment_slot: {quota: 5}
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in as a user without can_manage_settings permission' do
      before { generate_and_set_token(no_permission_user) }
       it "denies update of an appointment slot" do
        put :update, id: appt_slot.id, appointment_slot_preset: {quota: 5}
        expect(response.status).to eq(403)
      end
    end

    context 'When logged in as a order administrator' do
      before { generate_and_set_token(order_administrator) }
      it "allows a supervisor to modify an appointment slot" do
        put :update, id: appt_slot.id, appointment_slot: { day: 7 }
        expect(response.status).to eq(200)
      end

      it "prevents updating a timestamp that conflicts with another slot's timestamp" do
        timestamp = DateTime.parse('29th Oct 2018 16:30:00+08:00')
        FactoryBot.create :appointment_slot, timestamp: timestamp, quota: 10
        put :update, id: appt_slot.id, appointment_slot: { timestamp: timestamp }
        expect(response.status).to eq(422)
      end
    end
  end

  describe "DELETE /appointment_slots/1" do
    let!(:appt_slot) { FactoryBot.create :appointment_slot, timestamp: now, quota: 10 }

    context 'When not logged in' do
      it "denies destruction of an appointment slot" do
        delete :destroy, id: appt_slot.id
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in as a user without can_manage_settings permission' do
      before { generate_and_set_token(no_permission_user) }

      it "denies destruction of an appointment slot" do
        delete :destroy, id: appt_slot.id
        expect(response.status).to eq(403)
      end
    end

    context 'When logged in as a order administrator' do
      before { generate_and_set_token(order_administrator) }

      it "allows a supervisor to destroy an appointment slot" do
        id = appt_slot.id
        delete :destroy, id: id
        expect(response.status).to eq(200)
        expect(AppointmentSlot.find_by(id: id)).to eq(nil)
      end
    end
  end

  describe "Testing potential timezone issues" do
    before {
      (1..7).each { |i| FactoryBot.create :appointment_slot_preset, hours: 10, minutes: 30, day: i }
      generate_and_set_token(order_administrator)
    }

    it 'Should lock the following day if a utc timestamp is sent with a time >= 16:00' do
      post :create, appointment_slot: { quota: 0, timestamp: "2018-12-19T16:00:00.000Z", notes: "Closed on the 20th of december" }
      get :calendar, from: '2018-12-19', to: '2018-12-21'

      results = parsed_body['appointment_calendar_dates']
      expect(results.count).to eq(3)

      dec_19th = results[0];
      expect(dec_19th['date']).to eq("2018-12-19")
      expect(dec_19th['isClosed']).to eq(false)

      dec_20th = results[1];
      expect(dec_20th['date']).to eq("2018-12-20")
      expect(dec_20th['isClosed']).to eq(true)

      dec_21th = results[2];
      expect(dec_21th['date']).to eq("2018-12-21")
      expect(dec_21th['isClosed']).to eq(false)
    end
  end
end
