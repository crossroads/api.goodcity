require 'guid'

class Shareable < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :resource, polymorphic: true

  before_create :assign_public_id

  scope :non_expired, -> () { where("shareables.expires_at IS NULL OR shareables.expires_at > now()") }
  scope :of_type, -> (type) { where(resource_type: type) }

  class << self
    def public_uid_of(resource)
      Shareable.find_by(resource: resource).try(:public_uid)
    end
  end

  private

  def assign_public_id
    self.public_uid = Guid.new.to_s
  end
end
