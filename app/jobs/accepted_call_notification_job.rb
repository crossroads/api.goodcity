class AcceptedCallNotificationJob < ActiveJob::Base
  queue_as :default

  def perform(user_id, mobile)
    user     = User.find_by(id: user_id)
    reviewer = User.user_exist?(mobile)
    offer_id = user.try(:recent_active_offer_id)
    offer    = Offer.find_by(id: offer_id)
    text     = "Call from #{user.full_name} has been accepted \
      by #{reviewer.full_name}."

    PushService.new.send_notification(
      text:        text,
      entity_type: "offer",
      entity:      offer,
      channel:     Channel.reviewer)
  end
end
