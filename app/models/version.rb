require 'paper_trail/version'

class Version < PaperTrail::Version
  belongs_to :related, polymorphic: true
  scope :related_to, ->(object) {
    where('(item_id = :id AND item_type = :type) OR (related_id = :id AND related_type = :type)',
      id: object.id, type: object.class.name)
  }

  scope :related_to_multiple, ->(objects) {
    where('(item_id IN (:ids) AND item_type = :type) OR (related_id IN (:ids) AND related_type = :type)',
      ids: objects.map(&:id), type: objects.last.class.name)
  }

  def to_s
    "id:#{self.id} #{self.item_type}##{self.item_id} #{self.event}"
  end

  def self.past_month_activities(objects)
    related_to_multiple(objects).past_month
  end
end
