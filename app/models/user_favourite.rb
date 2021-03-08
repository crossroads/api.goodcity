class UserFavourite < ApplicationRecord
  include PushUpdatesMinimal

  LIMIT_PER_TABLE = 20

  belongs_to :favourite, polymorphic: true
  belongs_to :user

  after_create :apply_limit

  # Live update rules
  after_save :push_changes
  after_destroy :push_changes
  push_targets do |user_favourite|
    Channel.private_channels_for(user_favourite.user, STOCK_APP)
  end

  def apply_limit
    #
    # Delete non-persistent favorites > 20
    #
    UserFavourite.default_scoped
      .where(user_id: user_id, favourite_type: favourite_type, persistent: false)
      .order('updated_at')
      .offset(LIMIT_PER_TABLE)
      .destroy_all
  end

  class << self
    #
    # Mark a record as a favourite
    #
    def add_user_favourite(record, persistent: false, user: User.current_user)
      return unless user.present?

      UserFavourite.find_or_initialize_by(
        user: user,
        favourite: record,
      ) do |fav|
        fav.persistent = fav.persistent || persistent
        fav.updated_at = Time.current
        fav.save
      end
    end

    #
    # Removes a favourite
    #
    def remove_user_favourite(record, user: User.current_user)
      UserFavourite.where(user: user, favourite: record).destroy_all if user.present?
    end
  end
end
