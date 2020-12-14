# frozen_string_literal: true

module Api::V1
  class ProcessingDestinationsLookupSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name
  end
end
