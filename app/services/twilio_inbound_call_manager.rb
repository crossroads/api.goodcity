require "goodcity/redis"

class TwilioInboundCallManager

  DonorPrefix = "twilio_donor"
  NotifyPrefix = "twilio_notify"

  def initialize(options = {})
    @mobile = options[:mobile]
    @user_id = options[:user_id]
    @record_link = options[:record_link]
    @offer_id = options[:offer_id]
  end

  def offer_donor
    Offer.find_by(id: @offer_id).try(:created_by)
  end

  def caller_is_admin?
    caller.try(:staff?)
  end

  def caller_has_active_offer?
    return false if @mobile.blank?
    return false if caller.nil?
    caller_active_offers = caller.offers.non_draft
    staff_active = Version.past_month_activities(caller_active_offers, caller.id)
    return !(caller_active_offers.count.zero? && staff_active.count.zero?)
  end

  def set_mobile
    store(donor_id_key, @mobile)
  end

  def mobile
    redis.get(donor_id_key)
  end

  def call_teardown
    redis.del(donor_id_key)
    redis.del(notify_key)
  end

  def notify_incoming_call
    # notify only once when at least one worker is offline
    if redis.get(notify_key).blank?
      send_calling_notification
      incoming_call_version
      store(notify_key, true)
    end
  end

  def notify_accepted_call
    send_call_accept_notification
    call_accept_version
  end

  def send_donor_call_response
    if user && user.try(:recent_active_offer_id)
      # send message to supervisor general-messages thread of Offer
      offer.messages.create(
        sender:     user,
        is_private: true,
        body:       call_summary_text
      )
    end
  end

  def log_outgoing_call
    Version.create(
      event:     'admin_called',
      item_type: 'Offer',
      item_id:   @offer_id,
      whodunnit: caller.id.to_s
    )
  end

  private

  def call_summary_text
    if @record_link
      "Left message: <audio controls>
        <source src='#{@record_link}.mp3' type='audio/mpeg'>
      </audio>"
    else
      "Requested call-back:
      <a href='tel:#{user.mobile}' class='tel_link'><i class='fa fa-phone'></i>#{user.mobile}</a>"
    end
  end

  def notify_key
    "#{NotifyPrefix}_#{@user_id}"
  end

  def donor_id_key
    "#{DonorPrefix}_#{@user_id}"
  end

  def store(key, value)
    redis.setex(key, 60, value)
  end

  def incoming_call_version
    Version.create(
      event:     'donor_called',
      item_type: 'Offer',
      item_id:   offer.id,
      whodunnit: @user_id.to_s
    )
  end

  def call_accept_version
    Version.create(
      event:     'call_accepted',
      item_type: 'Offer',
      item_id:   offer.id,
      whodunnit: caller.id.to_s
    )
  end

  def send_calling_notification
    PushService.new.send_notification offer.call_notify_channels, true, {
      category:  'incoming_call',
      message:   "#{user.full_name} calling now..",
      author_id: @user_id,
      offer_id:  offer.id
    }
  end

  def send_call_accept_notification
    PushService.new.send_notification call_accepted_notify_channels, true, {
      category:  'call_answered',
      message:   call_accepted_message,
      author_id: @user_id,
      offer_id:  offer.id
    }
  end

  def call_accepted_message
    "Call from #{user.full_name} has been accepted by #{caller.full_name}"
  end

  def call_accepted_notify_channels
    offer.call_notify_channels - ["user_#{caller.id}"]
  end

  def user
    @user ||= User.find_by(id: @user_id)
  end

  def offer
    @offer ||= Offer.find(user.recent_active_offer_id)
  end

  def redis
    @redis ||= Goodcity::Redis.new
  end

  # caller is the user looked up via mobile (because they are calling)
  def caller
    @caller ||= User.find_by_mobile(@mobile) if @mobile.present?
  end

end
