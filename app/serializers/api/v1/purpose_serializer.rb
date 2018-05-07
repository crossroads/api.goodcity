module Api::V1
  class PurposeSerializer < ApplicationSerializer
    include FastJsonapi::ObjectSerializer
    embed :ids, include: true
    attributes :id, :name_en, :name_zh_tw
  end
end
