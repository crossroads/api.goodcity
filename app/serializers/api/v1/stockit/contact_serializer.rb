module Api::V1::Stockit
  class ContactSerializer < ApplicationSerializer
    attributes :id, :first_name, :last_name
  end
end
