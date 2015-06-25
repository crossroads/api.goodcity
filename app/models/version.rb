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

  scope :items_log, -> { where("(item_type = 'Item' AND
                    object_changes #>> '{state, 1}' <> '' OR
                    object_changes #>> '{donor_description, 1}' <> '' OR
                    object_changes #>> '{donor_condition_id, 1}' <> '') OR
                    (item_type = 'Package' AND object_changes #>> '{state, 1}'
                    IN (?))", %w(received missing))  }

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

  def valid_pusher_update?
    item_log? || item_package_log?
  end

  def item_log?
    self.item_type == "Item" &&
    (self.object_changes.keys & %w(donor_description donor_condition_id state)).present?
  end

  def item_package_log?
    self.item_type == "Package" && %w(received missing).include?(self.object_changes["state"][1])
  end
end
