module Api::V1
  class HolidaysController < Api::V1::ApiController
    load_and_authorize_resource :holiday, parent: false

    resource_description do
      short "List next available dates (excluding holidays)"
      formats ["json"]
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :holiday do
      param :holiday, Hash, required: true do
        param :holiday, String, desc: "Holiday date"
        param :name, String, desc: "Name of holiday"
      end
    end

    api :GET, "/v1/holidays/available_dates", "List all available dates"
    param :schedule_days, String, allow_nil: true,
      desc: "Number of next available days"
    param :start_from, String, allow_nil: true,
      desc: "Interval in number of days from when schedule start from current day"
    def available_dates
      days_count = params[:schedule_days] || NEXT_AVAILABLE_DAYS_COUNT
      start_from = params[:start_from] || START_DAYS_COUNT
      render json: DateSet.new(days_count, start_from).available_dates.map(&:to_date).to_json
    end

    api :POST, '/v1/holidays', "Create holiday"
    param_group :holiday
    def create
      @holiday = Holiday.new(holiday_params)
      if @holiday.save
        render json: @holiday, serializer: serializer, status: 201
      else
        render json: @holiday.errors.to_json, status: 422
      end
    end

    api :GET, '/v1/holidays', "List all holidays"
    description "List all future holidays"
    def index
      render json: @holidays.after(Date.today).order("holiday"), each_serializer: serializer, status: 200
    end

    api :DELETE, '/v1/holidays/1', "Delete holiday"
    def destroy
      @holiday.destroy
      render json: {}
    end

    api :PUT, '/v1/holidays/1', "Update holiday"
    param_group :holiday
    def update
      @holiday.update_attributes(holiday_params)
      render json: @holiday, serializer: serializer
    end

    private

    def holiday_params
      params.require(:holiday).permit(:holiday, :name)
    end

    def serializer
      Api::V1::HolidaySerializer
    end
  end
end
