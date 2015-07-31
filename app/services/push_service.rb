class PushService
  def send_update_store(channel, is_admin_app, data)
    channels = [channel].flatten
    channels = Channel.add_admin_app_prefix(channels) if is_admin_app
    SocketioSendJob.perform_later(channels, "update_store", data.to_json, true)
  end

  def send_notification(channel, is_admin_app, data)
    data[:date] = Time.now.to_json.tr('"','')
    channels = [channel].flatten
    channels = Channel.add_admin_app_prefix(channels) if is_admin_app
    SocketioSendJob.perform_later(channels, "notification", data.to_json)

    if Channel.user_channel?(channels)
      AzureNotifyJob.perform_later(channels, data, is_admin_app)
    end
  end
end
