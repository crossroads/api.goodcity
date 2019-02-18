class PushService
  def send_update_store(channels, app_name, data)
    # TODO remove add_app_name_suffix, decide correct channels further up
    channels = [channels].flatten.uniq
    channels = Channel.add_app_name_suffix(channels, app_name)
    if channels.any?
      SocketioSendJob.perform_later(channels, "update_store", data.to_json, true)
    end
  end

  def send_notification(channel, app_name, data)
    data[:message] = ActionView::Base.full_sanitizer.sanitize(data[:message])
    data[:date] = Time.now.to_json.tr('"','')
    # TODO remove add_app_name_suffix, decide correct channels further up
    channel = Channel.add_app_name_suffix(channel, app_name)
    SocketioSendJob.perform_later(channel, "notification", data.to_json)
    AzureNotifyJob.perform_later(channel, data, app_name)
  end
end
