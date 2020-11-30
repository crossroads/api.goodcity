class UserFavourite < ApplicationRecord
  include PushUpdatesMinimal

  LIMIT_PER_TABLE = 20
  
  belongs_to :favourite, polymorphic: true
  belongs_to :user
  
  after_create :apply_limit
  
  def apply_limit
    #
    # Delete non-persistent favorites > 20 
    #
    UserFavourite
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
      
      UserFavourite.where(
        user: user,
        favourite: record,
        persistent: persistent
      ).first_or_initialize do |fav|
        fav.save  if fav.new_record?
        fav.touch if fav.persisted?
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
