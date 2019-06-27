module OfferFiltering
  extend ActiveSupport::Concern

  included do
    scope :filter, -> (options = {}) do
      res = where(nil)
      res = where("offers.state IN (?)", options[:state_names]) unless options[:state_names].empty?
      res = res.priority if options[:priority].present?
      res = res.self_reviewer if options[:self_reviewer].present?
      res = res.due_after(options[:after]) if options[:after].present?
      res = res.due_before(options[:before]) if options[:before].present?
      res.distinct
    end

    def self.priority
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
  end
end
