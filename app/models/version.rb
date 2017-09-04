require 'paper_trail/version'

class Version < PaperTrail::Version
  include PushUpdates
  belongs_to :related, polymorphic: true

  scope :by_user, ->(user_id) { where('whodunnit = ?', user_id.to_s) }
  scope :except_user, ->(user_id) { where('whodunnit <> ?', user_id.to_s) }

  scope :related_to, ->(object) {
    where('(item_id = :id AND item_type = :type)
      OR (related_id = :id AND related_type = :type)',
      id: object.id, type: object.class.name)
  }

  scope :for_offers, ->{
    where('item_type = :type OR related_type = :type', type: "Offer") }

  scope :related_to_multiple, ->(objects) {
    where('(item_id IN (:ids) AND item_type = :type)
      OR (related_id IN (:ids) AND related_type = :type)',
      ids: objects.map(&:id), type: objects.last.class.name)
  }

  scope :item_logs, -> {
    joins("INNER JOIN items ON (items.id = versions.item_id
      AND versions.item_type = 'Item' AND items.deleted_at IS NULL)")
  }

  scope :package_logs, -> {
    joins("INNER JOIN packages ON packages.id = versions.item_id
      AND versions.item_type = 'Package'
      AND packages.item_id IS NOT NULL
      AND packages.deleted_at IS NULL")
  }

  scope :offer_logs, -> (offer_id) {
    joins("INNER JOIN offers ON versions.item_id = offers.id
      AND offers.id = #{offer_id}
      AND versions.item_type = 'Offer'
      AND versions.event IN ('call_Accepted', 'donor_called', 'admin_called')
      AND offers.deleted_at IS NULL")
  }

  scope :item_versions, -> (item_id) {
    joins(sanitize_sql_array(["INNER JOIN items ON (items.id = versions.item_id AND
      items.id = ? AND versions.item_type = 'Item' AND
      items.deleted_at IS NULL)", item_id]))
  }

  scope :package_versions, -> (item_id) {
    joins(sanitize_sql_array(["INNER JOIN packages ON packages.id = versions.item_id
      AND versions.item_type = 'Package'
      AND packages.item_id = ?
      AND packages.deleted_at IS NULL", item_id]))
  }

  scope :call_logs, -> {
    joins("INNER JOIN offers ON versions.item_id = offers.id
      AND versions.item_type = 'Offer'
      AND versions.event IN ('call_Accepted', 'donor_called', 'admin_called')
      AND offers.deleted_at IS NULL")
  }

  scope :union_all_logs, -> {
    "#{item_logs.to_sql} UNION ALL #{package_logs.to_sql} UNION ALL #{call_logs.to_sql}"
  }

  scope :items_and_calls_log, -> {
    find_by_sql("
      SELECT ver.id, event, item_id, item_type, whodunnit, object_changes, ver.created_at, concat(users.first_name,' ', users.last_name) as whodunnit_name, (object_changes -> 'state' -> 1) as state
      from (#{union_all_logs}) as ver INNER JOIN users ON users.id = CAST(ver.whodunnit AS integer)")
  }

  scope :join_users, -> {
    joins("inner join users ON users.id = CAST(versions.whodunnit AS integer)")
  }

  def to_s
    "id:#{id} #{item_type}##{item_id} #{event}"
  end

  def related_id_or_item_id
    related_id || item_id
  end

  def self.past_month_activities(objects, donor_id)
    past_month.related_to_multiple(objects).except_user(donor_id)
  end

  def self.active_offer_ids_in_past_fortnight
    stockit_user_id = User.stockit_user.try(:id).try(:to_s)
    except_user(stockit_user_id)
      .past_fortnight.for_offers
      .select("DISTINCT COALESCE(related_id, item_id) related_offer")
      .map(&:related_offer)
  end

  # required by PushUpdates and PaperTrail modules
  def offer
    return nil unless is_item_or_call_log?
    return item if item_type == "Offer"
    return related if related_type == "Offer"
  end

  def is_item_or_call_log?
    ['Item','Package'].include?(item_type) ||
    ['call_accepted','donor_called', 'admin_called'].include?(event)
  end
end
