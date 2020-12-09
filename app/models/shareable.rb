require 'guid'

class Shareable < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :resource, polymorphic: true

  before_create :assign_public_id

  private

  def assign_public_id
    self.public_uid = Guid.new.to_s
  end
end
