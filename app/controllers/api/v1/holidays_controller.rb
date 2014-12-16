module Api::V1
  class HolidaysController < Api::V1::ApiController

    load_and_authorize_resource :holiday, parent: false
    skip_before_action :validate_token, only: :available_dates

    def available_dates
      render json: DateSet.new(params[:schedule_days] || 10).available_dates.to_json
    end
  end
end
