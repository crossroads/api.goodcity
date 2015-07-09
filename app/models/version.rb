require 'paper_trail/version'

class Version < PaperTrail::Version
  include PushUpdates
  belongs_to :related, polymorphic: true

  scope :by_user, ->(user_id) { where('whodunnit = ?', user_id.to_s) }
  scope :except_user, ->(user_id) { where('whodunnit <> ?', user_id.to_s) }

  scope :related_to, ->(object) {
    where('(item_id = :id AND item_type = :type) OR (related_id = :id AND related_type = :type)',
      id: object.id, type: object.class.name)
  }

  scope :for_offers, ->{
    where('item_type = :type OR related_type = :type', type: "Offer") }

  scope :related_to_multiple, ->(objects) {
    where('(item_id IN (:ids) AND item_type = :type) OR (related_id IN (:ids) AND related_type = :type)',
      ids: objects.map(&:id), type: objects.last.class.name)
  }

  scope :items_and_calls_log, -> {
    where("item_type IN (?) or event IN (?)", %w(Item Package), %w(call_accepted donor_called))
  }

  def to_s
    "id:#{self.id} #{self.item_type}##{self.item_id} #{self.event}"
  end

  def self.past_month_activities(objects, donor_id)
    related_to_multiple(objects).except_user(donor_id).past_month
  end

  # required by PushUpdates and PaperTrail modules
  def offer
    related_type == "Offer" ? related : nil
  end
end
