class PushService
  def send_update_store(channel, is_admin_app, data)
    channel = Channel.add_admin_app_suffix(channel) if is_admin_app
    SocketioSendJob.perform_later(channel, "update_store", data.to_json, true)
  end

  def send_notification(channel, is_admin_app, data)
    data[:message] = ActionView::Base.full_sanitizer.sanitize(data[:message])
    data[:date] = Time.now.to_json.tr('"','')
    channel = Channel.add_admin_app_suffix(channel) if is_admin_app

    SocketioSendJob.perform_later(channel, "notification", data.to_json)
    AzureNotifyJob.perform_later(channel, data, is_admin_app)
  end
end
