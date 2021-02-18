class UserRole < ApplicationRecord
  has_paper_trail versions: { class_name: 'Version' }
  include PushUpdatesMinimal
  
  # Live update rules
  after_save :push_changes
  after_destroy :push_changes
  push_targets do |user_role|
    Channel.private_channels_for(user_role.user, BROWSE_APP)
  end
  
  belongs_to :user
  belongs_to :role

  validates :role_id, uniqueness: { scope: :user_id }

  def self.create_user_role(user_id, role_id)
    create(user_id: user_id, role_id: role_id)
  end
end
