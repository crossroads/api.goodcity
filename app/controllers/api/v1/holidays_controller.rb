module Api::V1
  class HolidaysController < Api::V1::ApiController

    load_and_authorize_resource :holiday, parent: false
    skip_before_action :validate_token, only: :holidays_list

    def holidays_list
      @holidays.between_times(Time.zone.now, Time.zone.now + 10.days)
      render json: @holidays.pluck(:holiday).to_json
    end

  end
end
