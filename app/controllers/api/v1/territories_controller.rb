module Api::V1
  class TerritoriesController < Api::V1::ApiController

    skip_before_action :validate_token, only: [:index, :show]
    load_and_authorize_resource :territory, parent: false

    def index
      params[:ids].blank? ? render_cached_results : render_filtered_results
    end

    def show
      render json: @territory, serializer: serializer
    end

    private

    def serializer
      Api::V1::TerritorySerializer
    end

    def territories
      Territory.with_eager_load
    end

    def render_filtered_results
      @territories = territories
      @territories = @territories.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @territories, each_serializer: serializer
    end

    def render_cached_results
      @territories = cached_territories_json
      if @territories.blank?
        @territories = ActiveModel::ArraySerializer.new(territories, each_serializer: serializer).to_json
        Rails.cache.write(territories_cache_key, @territories)
      end
      render(json: @territories)
    end

    def cached_territories_json
      @cached_territories ||= Rails.cache.fetch(territories_cache_key)
    end

    def territories_cache_key
      "territories:#{I18n.locale}"
    end

  end
end
