module AutoFavourite
  extend ActiveSupport::Concern

  included do
    before_save   :mark_recent_usage
    after_destroy :remove_from_favourites

    scope :recently_used, -> (user_id) {
      UserFavourite.where(favourite_type: self.class.name, user_id: user_id).order('updated_at desc')
    }
  end

  class_methods do
    @@auto_favourite_relations = false

    def auto_favourite(relations: [], enabled: true)
      @@auto_favourite_enabled = enabled
      @@auto_favourite_relations = relations
    end
  end

  private

  def mark_recent_usage
    return unless persisted?

    UserFavourite.add_user_favourite(self) if @@auto_favourite_enabled

    relations = @@auto_favourite_relations || []

    relations.each do |name|
      rel = try(name)
      if rel.present?
        foreign_key = _reflections[name].foreign_key
        UserFavourite.add_user_favourite(rel) if new_record? || send("#{foreign_key}_changed?")
      end
    end
  end

  def remove_from_favourites
    UserFavourite.remove_user_favourite(self)
  end
end
