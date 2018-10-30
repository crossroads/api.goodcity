module Api
  module V1
    class AppointmentSlotsController < Api::V1::ApiController
      load_and_authorize_resource :appointment_slot, parent: false
  
      resource_description do
        short 'Manage a list of appointment quotas for special days'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :appointment_slot do
        param :appointment_slot, Hash, required: true do
          param :timestamp, String
          param :quota, :number
        end
      end

      def appointment_slot_params
        params.require(:appointment_slot).permit([:timestamp, :quota])
      end

      api :GET, '/v1/appointment_slots', "List upcoming appointment slots"
      def index
        render json: @appointment_slots.upcoming.ascending, each_serializer: serializer, status: 200
      end

      api :GET, '/v1/appointment_slots/calendar', "List upcoming appointment slots aggregated by dates"
      def calendar
        from = params[:from] ? Date.parse(params[:from]) : Date.today
        to = Date.parse(params[:to])
        render json: AppointmentSlot.calendar(from, to).to_json, status: 200
      end

      api :POST, "/v1/appointment_slots", "Add or update an appointment slot"
      param_group :appointment_slot
      def create
        appt_slot = AppointmentSlot.find_or_create_by(timestamp: @appointment_slot.timestamp)
        appt_slot.quota = @appointment_slot.quota
        save_and_render_object(appt_slot)
      end

      api :DELETE, '/v1/appointment_slots/1', "Delete a preset appointment slot"
      def destroy
        @appointment_slot.destroy
        render json: {}
      end

      private

      def serializer
        Api::V1::AppointmentSlotSerializer
      end

    end
  end
end
