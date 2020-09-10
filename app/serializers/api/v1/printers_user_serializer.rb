module Api::V1
  class PrintersUserSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :printer_id, :user_id, :tag
  end
end