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
    PushService.new.send_notification call_notify_channels, ADMIN_APP, {
      category:  'incoming_call',
      message:   "#{user.full_name} calling now..",
      author_id: @user_id,
      offer_id:  offer.id
    }
  end

  def send_call_accept_notification
    PushService.new.send_notification call_accepted_notify_channels, ADMIN_APP, {
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
    call_notify_channels - ["user_#{caller.id}"]
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

  # TODO: ask Matt if we should change the logic here to always include all reviewers
  # Notify all the offer's subscribed admins that a new call is incoming
  # If none exist, notify all supervisors
  def call_notify_channels
    reviewer_channel = Channel.private_channels_for(offer.reviewed_by_id, ADMIN_APP)
    subscribed_staff = Message.unscoped.joins(:subscriptions)
      .select("distinct subscriptions.user_id as user_id")
      .where(is_private: true, offer_id: offer.id)
      .map(&:user_id)
    channel_names = Channel.private_channels_for(subscribed_staff, ADMIN_APP)
    if (channel_names - reviewer_channel).blank?
      channel_names = Channel.private_channels_for(User.supervisors.pluck(:id), ADMIN_APP)
    end
    channel_names += reviewer_channel
    channel_names.flatten.uniq.compact
  end

end
