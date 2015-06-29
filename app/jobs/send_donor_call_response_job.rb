class SendDonorCallResponseJob  < ActiveJob::Base
  queue_as :default

  def perform(user_id, record_link = nil)
    user = User.find_by(id: user_id) if user_id
    offer_id = user.try(:recent_active_offer_id)

    if user && offer_id
      offer = Offer.find_by(id: offer_id)
      text = if record_link
        "Left message: <audio controls>
          <source src='#{record_link}.mp3' type='audio/mpeg'>
        </audio>"
      else
        "Requested call-back:
        <a href='tel:#{user.mobile}' class='tel_link'><i class='fa fa-phone'></i>#{user.mobile}</a>"
      end

      # send message to supervisor general-messages thread of Offer
      offer.messages.create(
        sender: user,
        is_private: true,
        body: text
      )
    end
  end
end
