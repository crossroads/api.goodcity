class AzureNotificationsService
  def notify(tags, data, collapse_key = nil, delay_while_idle = false)
    tags = tags.join(' || ') if tags.instance_of?(Array)
    headers = {
      'ServiceBusNotification-Format' => 'gcm',
      'ServiceBusNotification-Tags' => tags,
      'Content-Type' => 'application/json;charset=utf-8'
    }
    body = { data: data }
    body[:collapse_key] = collapse_key unless collapse_key.nil?
    body[:delay_while_idle] = delay_while_idle
    send :post, 'messages', body: body.to_json, headers: headers
  end

  def register_device(handle, tags)
    res = send :get, "registrations?$filter=#{URI::encode("GcmRegistrationId eq '#{handle}'")}"
    Nokogiri::XML(res.decoded).css('entry title').each {|n| send :delete, "registrations/#{n.content}", headers: {'If-Match'=>'*'}}
    res = send :post, 'registrationIDs'
    # Location = https://{namespace}.servicebus.windows.net/{NotificationHub}/registrations/<registrationId>?api-version=2014-09
    regId = res.headers['location'].split('/').last.split('?').first
    body =
      "<?xml version=\"1.0\" encoding=\"utf-8\"?>
      <entry xmlns=\"http://www.w3.org/2005/Atom\">
          <content type=\"application/xml\">
              <GcmRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\">
                  <Tags>#{tags.join(', ')}</Tags>
                  <GcmRegistrationId>#{handle}</GcmRegistrationId>
              </GcmRegistrationDescription>
          </content>
      </entry>"
    send :put, "registrations/#{regId}", body: body
  end

  def send(method, resource, options = {})
    sep = resource.include?('?') ? '&' : '?'
    url = "#{settings['endpoint']}/#{resource}#{sep}api-version=2014-09"
    options[:method] = method
    options[:headers] ||= {}
    options[:headers]['Authorization'] = sas_token(url)
    Nestful::Request.new(url, options).execute
  end

  private

  def sas_token(url, lifetime: 10)
    target_uri = CGI.escape(url.downcase).gsub('+', '%20').downcase
    expires = Time.now.to_i + lifetime
    to_sign = "#{target_uri}\n#{expires}"
    signature = CGI.escape(Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', settings['key'], to_sign))).gsub('+', '%20')
    "SharedAccessSignature sr=#{target_uri}&sig=#{signature}&se=#{expires}&skn=#{settings['key_name']}"
  end

  def settings
    Rails.application.secrets.azure_notifications
  end
end
