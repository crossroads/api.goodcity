class PushService
  def send_update_store(channel, data)
    SocketioSendJob.perform_later([channel].flatten, "update_store", data.to_json, true)
  end

  def send_notification(channel, is_admin_app, data)
    data[:date] = Time.now.to_json.tr('"','')
    SocketioSendJob.perform_later([channel].flatten, "notification", data.to_json)

    if Channel.user_channel?(channel)
      AzureNotifyJob.perform_later(channel, data, is_admin_app)
    end
  end
end
