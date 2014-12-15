module Api::V1
  class HolidaysController < Api::V1::ApiController

    load_and_authorize_resource :holiday, parent: false
    skip_before_action :validate_token, only: [:holidays_list, :available_dates]

    def holidays_list
      @holidays.between_times(Time.zone.now, Time.zone.now + 20.days)
      render json: @holidays.pluck(:holiday).to_json
    end

    def available_dates
      render json: DateSet.new(params[:schedule_days]).available_dates.to_json
    end
  end
end
