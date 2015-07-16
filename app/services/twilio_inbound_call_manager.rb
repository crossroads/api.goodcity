require "goodcity/redis"

class TwilioInboundCallManager

  DonorPrefix  = "twilio_donor"
  NotifyPrefix = "twilio_notify"

  def initialize(options = {})
    @admin_mobile = options[:admin_mobile]
    @user_id      = options[:user_id]
    @record_link  = options[:record_link]
  end

  def self.caller_has_active_offer?(mobile)
    return false if mobile.blank?
    return false if (donor = User.find_by_mobile(mobile)).nil?
    donor_active_offers = donor.offers.non_draft
    staff_active = Version.past_month_activities(donor_active_offers, donor.id)
    return !(donor_active_offers.count.zero? && staff_active.count.zero?)
  end

  def set_mobile
    store(donor_id_key, @admin_mobile)
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
    offer_id = user.try(:recent_active_offer_id)

    if user && offer_id
      text = if @record_link
        "Left message: <audio controls>
          <source src='#{@record_link}.mp3' type='audio/mpeg'>
        </audio>"
      else
        "Requested call-back:
        <a href='tel:#{user.mobile}' class='tel_link'><i class='fa fa-phone'></i>#{user.mobile}</a>"
      end

      # send message to supervisor general-messages thread of Offer
      offer.messages.create(
        sender:     user,
        is_private: true,
        body:       text
      )
    end
  end

  private

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
      item_type:    'Offer',
      item_id:      offer.id,
      event:        'call_accepted',
      whodunnit:    receiver.id.to_s
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
    PushService.new.send_notification offer.call_notify_channels - ["user_#{receiver.id}"], true, {
      category:   'call_answered',
      message:    "Call from #{user.full_name} has been accepted by #{receiver.full_name}",
      author_id:  @user_id,
      offer_id:   offer.id
    }
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

  def receiver
    @receiver ||= User.find_by_mobile(@admin_mobile)
  end

end
