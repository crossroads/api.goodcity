module Api::V1
  class PrintersUserSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :printer_id, :user_id, :tag

    has_one :printer, serializer: PrinterSerializer
    has_one :user, serializer: UserSerializer
  end
end