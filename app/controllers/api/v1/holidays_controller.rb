module Api::V1
  class HolidaysController < Api::V1::ApiController
    load_and_authorize_resource :holiday, parent: false
    skip_before_action :validate_token, only: :available_dates

    resource_description do
      short "List next available dates (excluding holidays)"
      formats ["json"]
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
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
  end
end
