require 'sidekiq/api'

namespace :goodcity do

  # rake goodcity:queue_ggv_polling
  desc 'Queue GGV polling job for GGV-orders'
  task queue_ggv_polling: :environment do

    # Fetch order-ids from scheduled-ggv-polling jobs
    scheduled_set = Sidekiq::ScheduledSet.new
    job_arguments = scheduled_set.map(&:args).flatten
    order_ids = []
    job_arguments.each do |job|
      order_ids << job["arguments"] if job["job_class"] == "PollGogovanOrderStatusJob"
    end
    order_ids.flatten!

    # schedule GGV-polling job if not scheduled already
    orders = GogovanOrder.where("status IN (?)", ["active", "pending"])
    orders.each do |order|
      if order_ids.exclude? order.id
        PollGogovanOrderStatusJob.perform_later(order.id)
      end
    end
  end
end
