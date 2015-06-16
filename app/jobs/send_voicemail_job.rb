class SendVoicemailJob  < ActiveJob::Base
  queue_as :default

  def perform(record_link, user_id)
    user = User.find_by(id: user_id) if user_id
    offer_id = user.try(:recent_active_offer_id)

    if user && offer_id
      offer = Offer.find_by(id: offer_id)
      text = "Voicemail Received from #{user.full_name}<br>
        <audio controls>
          <source src='#{record_link}.mp3' type='audio/mpeg'>
        </audio>"

      # send message to supervisor general-messages thread of Offer
      offer.messages.create(
        sender: User.system_user,
        is_private: true,
        body: text
      )
    end
  end
end
