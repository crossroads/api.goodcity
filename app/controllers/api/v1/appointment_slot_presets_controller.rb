module Api
  module V1
    class AppointmentSlotPresetsController < Api::V1::ApiController
      load_and_authorize_resource :appointment_slot_preset, parent: false
  
      resource_description do
        short 'Manage a list of appointment slot templates for days of the week.'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :appointment_slot_preset do
        param :appointment_slot_preset, Hash, required: true do
          param :hours, :number
          param :minutes, :number
          param :quota, :number
          param :day, :number
        end
      end

      def appointment_slot_preset_params
        params.require(:appointment_slot_preset).permit([:hours, :minutes, :day, :quota])
      end

      api :GET, '/v1/appointment_slot_presets', "List all preset appointment slots"
      def index
        render json: @appointment_slot_presets.ascending, each_serializer: serializer, status: 200
      end

      api :POST, "/v1/appointment_slot_presets", "Add a preset appointment slot"
      param_group :appointment_slot_preset
      def create
        preset = AppointmentSlotPreset.find_or_create_by(
          day: @appointment_slot_preset.day, 
          hours: @appointment_slot_preset.hours, 
          minutes: @appointment_slot_preset.minutes
        )
        preset.quota = @appointment_slot_preset.quota
        save_and_render_object(preset)
      end

      api :PUT, '/v1/appointment_slot_presets/1', "Update a preset appointment slot"
      param_group :appointment_slot_preset
      def update
        if @appointment_slot_preset.update_attributes(appointment_slot_preset_params)
          render json: @appointment_slot_preset, serializer: serializer
        else
          render json: @appointment_slot_preset.errors, status: 422
        end
      end

      api :DELETE, '/v1/appointment_slot_presets/1', "Delete a preset appointment slot"
      def destroy
        @appointment_slot_preset.destroy
        render json: {}
      end

      def serializer
        Api::V1::AppointmentSlotPresetSerializer
      end

    end
  end
end
