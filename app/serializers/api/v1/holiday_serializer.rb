module Api::V1
  class HolidaySerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :holiday, :name, :year
  end
end
