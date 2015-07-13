class SendOutboundCallStatus

  def initialize(user_id, offer_id, status)
    @user   = User.find_by(id: user_id)
    @offer  = Offer.find_by(id: offer_id)
    @status = status
  end

  def notify
    if(@user && @offer)
      text = if @status == "completed"
          "Called #{@offer.created_by.full_name}"
        else
          "Call attempt failed: #{@status.titleize}"
        end

      @offer.messages.create(
        body: text,
        sender: @user,
        is_private: true,
        is_call_log: true
      )
    end
  end
end
