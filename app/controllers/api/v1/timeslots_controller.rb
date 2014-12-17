module Api::V1
  class TimeslotsController < Api::V1::ApiController

    load_and_authorize_resource :timeslot, parent: false
    skip_before_action :validate_token, only: :index

    def index
      if params[:ids].blank?
        render json: Timeslot.cached_json
        return
      end
      @timeslots = @timeslots.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @timeslots, each_serializer: serializer
    end

    private

    def serializer
      Api::V1::TimeslotSerializer
    end

  end
end
