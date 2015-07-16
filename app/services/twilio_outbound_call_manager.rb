require "goodcity/redis"

class TwilioOutboundCallManager

  OutBoundCallPrefix = "twilio_outbound"

  def initialize(options = {})
    @call_to  = options[:to]
    @offer_id = options[:offer_id]
    @user_id  = options[:user_id]
  end

  def offer_id
    data["offer_id"]
  end

  def user_id
    data["user_id"]
  end

  def store
    redis.mapped_hmset(key, { offer_id: @offer_id, user_id: @user_id })
  end

  def remove
    redis.del(key)
  end

  private

  def data
    redis.hgetall key
  end

  def key
    "#{OutBoundCallPrefix}_#{@call_to}"
  end

  def redis
    @redis ||= Goodcity::Redis.new
  end

end
