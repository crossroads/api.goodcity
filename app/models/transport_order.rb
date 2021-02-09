class TransportOrder < ApplicationRecord
  belongs_to :transport_provider
  belongs_to :source, polymorphic: true
end
