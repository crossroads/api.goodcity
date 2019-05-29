module Api::V1
  class GoodcitySettingSerializer < ApplicationSerializer
    attributes :id, :key, :value, :description
  end
end
