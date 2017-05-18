module Api::V1
  class SchedulesController < Api::V1::ApiController

    skip_before_action :validate_token, only: [:availableTimeSlots]
    load_and_authorize_resource :schedule, parent: false

    resource_description do
      short "Schedule will help donors to plan their donation pick up."
      formats ["json"]
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :schedule do
      param :schedule, Hash, required: true do
        param :resource, String, desc: "Transport Type", allow_nil: true
        param :slot, Integer, desc: "Time slot for the pick up e.g. slot 1 or slot2 etc", allow_nil: true
        param :scheduled_at, String, desc: "Date and time of the pick up e.g Tuesday 23 October 2014, 10:30 am."
        param :slot_name, String, desc: "Slot timing details e.g. Morning,11am-1pm or Afternoon,2pm-4pm etc"
        param :zone, String, desc: "zone for selection e.g. East, West, North etc", allow_nil: true
      end
    end

    api :GET, "/v1/schedules", "List of available schedules for current week"
    def availableTimeSlots
      result_hash = HashWithIndifferentAccess.new(AVAILABLESLOTS).map {|_k,v| v}
      last_id = Schedule.last.try(:id) || 1
      @schedules  = result_hash.each_with_index do |k,i|
        k[:scheduled_at] = Time.now.utc + 1.weeks + k["scheduled_at"].day
        k.store("id", last_id + i + 1)
      end
      render json: @schedules
    end

    api :POST, "/v1/schedules", "Make a booking for the pick up"
    param_group :schedule
    def create
      @schedule.attributes = schedule_params
      if @schedule.save
        render json: @schedule, serializer: serializer, status: 201
      else
        render json: @schedule.errors.to_json, status: 422
      end
    end

    private

    def serializer
      Api::V1::ScheduleSerializer
    end

    def schedule_params
      params.require(:schedule).permit(:resource, :slot, :scheduled_at,
        :slot_name, :zone)
    end
  end
end
