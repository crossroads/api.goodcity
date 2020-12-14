# frozen_string_literal: true
module Api
  module V1
    class ProcessingDestinationsLookupsController < Api::V1::ApiController
      load_and_authorize_resource :processing_destinations_lookup, parent: false
    
      def index
        render json: @processing_destinations_lookups, each_serializer: serializer 
      end
    
      private
    
      def serializer
        Api::V1::ProcessingDestinationsLookupSerializer
      end
    end  
  end
end
