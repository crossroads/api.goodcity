module Api::V1
  class AccessPassSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :access_key, :generated_by_id, :generated_at, :access_expires_at
  end
end
