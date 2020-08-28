class PushService
  @@locked = false

  def self.locked
    @@locked = true
    yield
    @@locked = false
  end

  def send_update_store(channels, data)
    return if @@locked

    channels = [channels].flatten.uniq
    payload = default_payload.merge(data)
    if channels.any?
      SocketioSendJob.perform_later(channels, "update_store", payload.to_json, false)
    end
  end

  def send_notification(channels, app_name, data)
    return if @@locked

    data[:message] = ActionView::Base.full_sanitizer.sanitize(data[:message])
    data[:date] = Time.now.to_json.tr('"','')
    channels = [channels].flatten.uniq
    if channels.any?
      SocketioSendJob.perform_later(channels, "notification", data.to_json)
      AzureNotifyJob.perform_later(channels, data, app_name)
    end
  end

  private

  def default_payload
    { device_id: User.current_device_id || '' }
  end
end
