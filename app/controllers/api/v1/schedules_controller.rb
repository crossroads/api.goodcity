module Api::V1
  class SchedulesController < Api::V1::ApiController

    skip_before_action :validate_token, only: [:availableTimeSlots]
    load_and_authorize_resource :schedule, parent: false

    def availableTimeSlots
      result_hash = HashWithIndifferentAccess.new(AVAILABLESLOTS).map {|k,v| v}
      @schedules  = result_hash.each_with_index{|k,i|
                      k[:scheduled_at] = "#{Time.now + 1.weeks + k["scheduled_at"]}"
                      k.store("id", i+1)
                    }
      render json: @schedules
    end

    def create
      @schedule.attributes = schedule_params
      if @schedule.save
        render json: @schedule, serializer: serializer, status: 201
      else
        render json: @schedule.errors.to_json, status: 500
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
