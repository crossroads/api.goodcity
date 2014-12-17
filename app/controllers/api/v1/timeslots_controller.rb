module Api::V1
  class TimeslotsController < Api::V1::ApiController

    load_and_authorize_resource :timeslot, parent: false
    skip_before_action :validate_token, only: :index

    resource_description do
      short "List all time-slots."
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/timeslots', "List all time-slots"
    def index
      render json: @timeslots, each_serializer: serializer
    end

    private

    def serializer
      Api::V1::TimeslotSerializer
    end

  end
end
