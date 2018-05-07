module Api::V1
  class HolidaySerializer < ApplicationSerializer
    include FastJsonapi::ObjectSerializer
    embed :ids, include: true

    attributes :id, :holiday, :name, :year
  end
end
