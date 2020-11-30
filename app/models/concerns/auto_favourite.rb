module AutoFavourite
  extend ActiveSupport::Concern
  
  included do
    after_create  :mark_recent_usage
    after_update  :mark_recent_usage
    after_destroy :remove_from_favourites
    
    scope :recently_used, -> (user_id) {
      joins(%{
        LEFT JOIN user_favourites ON user_favourites.favourite_type = '#{self.class.name}' AND user_favourites.user_id = #{user_id}
      }).order('user_favourites.updated_at').limit(20)
    }
  end
  
  class_methods do
    def auto_favourite(enabled = true)
      @@auto_favourite_enabled = enabled
    end
    
    def auto_favourite_relations(relations = [])
      @@auto_favourite_relations = relations
    end
  end
  
  private
  
  def mark_recent_usage    
    UserFavourite.add_user_favourite(self) if @@auto_favourite_enabled
    
    relations = @@auto_favourite_relations || []
    
    relations.each do |name|
      rel = self.try(name)
      if rel.present?
        foreign_key = self._reflections[name].foreign_key
        UserFavourite.add_user_favourite(rel) #if self["#{foreign_key}_changed?"].present?
      end
    end
  end
  
  def remove_from_favourites
    UserFavourite.remove_user_favourite(self)
  end
end
