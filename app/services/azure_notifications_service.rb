class AzureNotificationsService
  def notify(platform, tags, data, collapse_key: nil)
    tags = tags.join(' || ') if tags.instance_of?(Array)
    headers = {
      'ServiceBusNotification-Format' => platform,
      'ServiceBusNotification-Tags' => tags
    }
    body = { data: data }
    body[:collapse_key] = collapse_key unless collapse_key.nil?
    send :post, 'messages', body: body, headers: headers
  end

  def register_device(handle, platform, tags)
    res = send :get, "registrations?$filter=GcmRegistrationId eq '#{handle}'"
    res.decoded.each {|r| send :delete, 'registrations/#{r.id}'}
    res = send :post, 'registrationIDs'
    # Content-Location = https://{namespace}.servicebus.windows.net/{NotificationHub}/registrations/<registrationId>
    regId = res[:headers]['Content-Location'].split('/').last
    send :put, 'registrations/#{regId}', body: {Handle: handle, Platform: platform, Tags: tags}
  end

  def send(method, resource, options = {})
    sep = resource.include?('?') ? '&' : '?'
    url = "#{settings['endpoint']}/#{resource}#{sep}api-version=2014-09"
    options[:method] = method
    options[:format] = :json
    options[:headers] ||= {}
    options[:headers]['Authorization'] = sas_token(url)
    response = Nestful::Request.new(url, options).execute
    # todo add error handling - response.status != 200
    # response.decoded
  end

  private

  def sas_token(url, lifetime: 10)
    target_uri = CGI.escape(url.downcase).gsub('+', '%20').downcase
    expires = Time.now.to_i + lifetime
    to_sign = "#{target_uri}\n#{expires}"
    signature = CGI.escape(Base64.strict_encode64(Digest::HMAC.digest(to_sign, settings['key'], Digest::SHA256))).gsub('+', '%20')
    "SharedAccessSignature sr=#{target_uri}&sig=#{signature}&se=#{expires}&skn=#{settings['key_name']}"
  end

  def settings
    Rails.application.secrets.azure_notifications
  end
end
