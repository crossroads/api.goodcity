require 'guid'

class Shareable < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :resource, polymorphic: true

  before_create :assign_public_id

  scope :non_expired, -> () { where("shareables.expires_at IS NULL OR shareables.expires_at > now()") }
  scope :of_type, -> (type) { where(resource_type: type) }

  validates :resource_id,   presence: true
  validates :resource_type, presence: true

  class << self
    def public_uid_of(resource)
      Shareable.find_by(resource: resource).try(:public_uid)
    end

    def shared_resource?(resource)
      return false unless resource.present?
      Shareable.non_expired.where(resource: resource).limit(1).first.present?
    end

    #
    # Create a shareable record for the spiecified resource
    #
    # @param [Model] resource the record to publish
    # @param [Time] expiry (opt) the expiry date of the shareable record
    # @param [User] author the publisher
    #
    # @return [Shareable] the shareable record
    #
    def publish(resource, expiry: nil, author: User.current_user || User.system_user)
      ActiveRecord::Base.transaction do
        Shareable.where(resource: resource).destroy_all
        Shareable.create({
          resource:   resource,
          expires_at: expiry,
          created_by: author
        })
      end
    end
  end

  private

  def assign_public_id
    self.public_uid = Guid.new.to_s
  end
end
