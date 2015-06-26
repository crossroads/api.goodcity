class SendDonorCallingNotificationJob < ActiveJob::Base
  queue_as :default

  def perform(user_id)
    user     = User.find_by(id: user_id)
    offer_id = user.try(:recent_active_offer_id)
    offer    = Offer.find_by(id: offer_id)
    text     = "#{user.full_name} calling now: "

    PushService.new.send_notification(
      text:        text,
      entity_type: "offer",
      entity:      offer,
      channel:     offer.call_notify_channels,
      call:        true)
  end
end
