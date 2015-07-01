class SendOutboundCallStatusJob < ActiveJob::Base
  queue_as :default

  def perform(user_id, offer_id, status)
    user  = User.find_by(id: user_id)
    offer = Offer.find_by(id: offer_id)

    if(user && offer)
      text = if status == "completed"
          "Called #{offer.created_by.full_name}"
        else
          "Call attempt failed: #{status.titleize}"
        end

      offer.messages.create(body: text, sender: user, is_private: true)
    end
  end
end
