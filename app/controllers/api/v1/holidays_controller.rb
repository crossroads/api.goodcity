module Api::V1
  class HolidaysController < Api::V1::ApiController

    load_and_authorize_resource :holiday, parent: false
    skip_before_action :validate_token, only: :available_dates

    def available_dates
      days_count = params[:schedule_days] || NEXT_AVAILABLE_DAYS_COUNT
      render json: DateSet.new(days_count).available_dates.to_json
    end
  end
end
