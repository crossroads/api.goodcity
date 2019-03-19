module Api::V1
  class UserSummarySerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :first_name, :last_name
  end
end
