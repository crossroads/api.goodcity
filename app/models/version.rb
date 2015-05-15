require 'paper_trail/version'

class Version < PaperTrail::Version
  belongs_to :related, polymorphic: true
  scope :related_to, ->(object) {
    where('(item_id = :id AND item_type = :type) OR (related_id = :id AND related_type = :type)',
      id: object.id, type: object.class.name)
  }

  def to_s
    "id:#{self.id} #{self.item_type}##{self.item_id} #{self.event}"
  end
end
