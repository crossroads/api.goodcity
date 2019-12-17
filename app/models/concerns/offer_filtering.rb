module OfferFiltering
  extend ActiveSupport::Concern

  included do
    # filter method expects any of the following options in params:
    #   -[:state_names] = ['submitted', 'reviewed'...]
    #   -[:priority] = boolean true or false
    #   -[:self_reviewer] = boolean  true or false
    #   -[:before] = timestamp
    #   -[:after] = timestamp

    scope :filter, -> (options = {}) do
      res = where.not(state: 'draft')
      res = res.assoicate_delivery_and_schedule
      res = res.where("offers.state IN (?)", options[:state_names]) unless options[:state_names].empty?
      res = res.priority if options[:priority].present?
      res = res.self_reviewer if options[:self_reviewer].present?
      res = res.due_after(options[:after]) if options[:after].present?
      res = res.due_before(options[:before]) if options[:before].present?
      res = res.order(sort_offer(options)) if options[:column] || options[:recent_offers]
      res = res.with_notifications(options[:with_notifications]) if options[:with_notifications].present?
      res.distinct
    end

    def self.priority
      where <<-SQL
        (offers.state = 'scheduled' AND schedules.scheduled_at::timestamptz < timestamptz '#{Time.zone.now}') OR
        (offers.state = 'reviewed' AND review_completed_at::timestamptz < '#{48.hours.ago}') OR
        (offers.state = 'under_review' AND reviewed_at::timestamptz < '#{24.hours.ago}') OR
        (offers.state = 'receiving' AND start_receiving_at::timestamptz < timestamptz '#{last_6pm}')
      SQL
    end

    def self.sort_offer(options)
      return "id DESC" if options[:recent_offers]
      sort_type = options[:is_desc] ? "DESC" : "ASC"
      "#{options[:column]} #{sort_type}"
    end

    def self.self_reviewer
      where("reviewed_by_id= ?", User.current_user.id)
    end

    def self.due_after(time)
      where('schedules.scheduled_at >= (?)', time)
    end

    def self.due_before(time)
      where('schedules.scheduled_at <= (?)', time)
    end

    def self.with_notifications(state)
      res = joins("LEFT OUTER JOIN subscriptions ON offers.id = subscriptions.offer_id")
      res = res.where("subscriptions.user_id = (?)", User.current_user.id)
      res = res.where("subscriptions.state = (?)", state) if %w[unread read].include?(state)
      res
    end

    # Helpers
    def self.last_6pm
      now = Time.now.in_time_zone
      t = now.change(hour: 18, min: 0, sec: 0)
      t -= 24.hours if now < t
      t
    end

    def self.assoicate_delivery_and_schedule
      res = joins("LEFT OUTER JOIN deliveries ON offers.id = deliveries.offer_id")
      res = res.joins("LEFT OUTER JOIN schedules ON deliveries.schedule_id = schedules.id")
      res
    end
  end
end
