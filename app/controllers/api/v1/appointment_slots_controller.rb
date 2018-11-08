module Api
  module V1
    class AppointmentSlotsController < Api::V1::ApiController
      MAX_CALENDAR_RANGE = 2.years

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
          param :note, String
          param :quota, :number
        end
      end

      def appointment_slot_params
        params.require(:appointment_slot).permit([:timestamp, :quota, :note])
      end

      api :GET, '/v1/appointment_slots', "List upcoming appointment slots"
      def index
        render_with_timezone(@appointment_slots.upcoming.ascending)
      end

      api :GET, '/v1/appointment_slots/calendar', "List upcoming appointment slots aggregated by dates"
      def calendar
        from = params[:from] ? Date.parse(params[:from]) : Date.today
        to = ceil(Date.parse(params[:to]), from + MAX_CALENDAR_RANGE)
        render json: AppointmentSlot.calendar(from, to).to_json, status: 200
      end

      api :POST, "/v1/appointment_slots", "Add an appointment slot"
      param_group :appointment_slot
      def create
        save_and_render_with_timezone(@appointment_slot, 201)
      end

      api :PUT, '/v1/appointment_slots/1', "Update an appointment slot"
      param_group :appointment_slot
      def update
        if @appointment_slot.update_attributes(appointment_slot_params)
          render_with_timezone(@appointment_slot)
        else
          render json: @appointment_slot.errors, status: 422
        end
      end

      api :DELETE, '/v1/appointment_slots/1', "Delete a preset appointment slot"
      def destroy
        @appointment_slot.destroy
        render json: {}
      end

      private

      def render_with_timezone(data, status = 200)
        if data.is_a?(AppointmentSlot)
          data.timestamp = data.timestamp.in_time_zone
          render json: { appointment_slot: data }, status: status
        else
          data.each { |s| s.timestamp = s.timestamp.in_time_zone }
          render json: { appointment_slots: data }, status: status
        end
      end

      def save_and_render_with_timezone(object, status = 200)
        if object.save
          render_with_timezone(object, status)
        else
          render json: object.errors, status: 422
        end
      end

      def ceil(val, max)
        return val > max ? max : val
      end

    end
  end
end
