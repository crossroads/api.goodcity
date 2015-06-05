class AzureNotificationsService
  def notify(tags, data, collapse_key = nil, delay_while_idle = nil)
    tags = tags.join(' || ') if tags.instance_of?(Array)
    headers = {
      'ServiceBusNotification-Format' => 'template',
      'ServiceBusNotification-Tags' => tags,
      'Content-Type' => 'application/json;charset=utf-8'
    }
    body = data
    body[:collapse_key] = collapse_key unless collapse_key.nil?
    body[:delay_while_idle] = delay_while_idle unless collapse_key.nil?
    send :post, 'messages', body: body.to_json, headers: headers
  end

  def register_device(handle, tags, platform)
    res = send :get, "registrations?$filter=#{URI::encode("GcmRegistrationId eq '#{handle}'")}"
    Nokogiri::XML(res.decoded).css('entry title').each {|n| send :delete, "registrations/#{n.content}", headers: {'If-Match'=>'*'}}
    res = send :post, 'registrationIDs'
    # Location = https://{namespace}.servicebus.windows.net/{NotificationHub}/registrations/<registrationId>?api-version=2014-09
    regId = res.headers['location'].split('/').last.split('?').first

    # platform
    # https://msdn.microsoft.com/en-us/library/azure/dn223265.aspx
    body = ""
    if platform == "gcm"
      template = '{"data":{"message":"$(message)"}}'
      body =
        "<?xml version=\"1.0\" encoding=\"utf-8\"?>
        <entry xmlns=\"http://www.w3.org/2005/Atom\">
          <content type=\"application/xml\">
            <GcmTemplateRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\">
              <Tags>#{tags.join(', ')}</Tags>
              <GcmRegistrationId>#{handle}</GcmRegistrationId>
              <BodyTemplate><![CDATA[#{template}]]></BodyTemplate>
            </GcmTemplateRegistrationDescription>
          </content>
        </entry>"
    elsif platform == "aps"
      template = '{"aps":{"alert":"$(message)"}}'
      body =
        "<?xml version=\"1.0\" encoding=\"utf-8\"?>
        <entry xmlns=\"http://www.w3.org/2005/Atom\">
          <content type=\"application/xml\">
            <AppleTemplateRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\">
              <Tags>#{tags.join(', ')}</Tags>
              <DeviceToken>#{handle}</DeviceToken>
              <BodyTemplate><![CDATA[#{template}]]></BodyTemplate>
            </AppleTemplateRegistrationDescription>
          </content>
        </entry>"
    elsif platform == "wns"
      template =
        "<toast>
          <visual>
            <binding template=\"ToastText01\">
              <text id=\"1\">$(message)</text>
            </binding>
          </visual>
        </toast>"
      body =
        "<?xml version=\"1.0\" encoding=\"utf-8\"?>
        <entry xmlns=\"http://www.w3.org/2005/Atom\">
          <content type=\"application/xml\">
            <WindowsTemplateRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\">
              <Tags>#{tags.join(', ')}</Tags>
              <ChannelUri>#{handle}</ChannelUri>
              <BodyTemplate><![CDATA[#{template}]]></BodyTemplate>
              <WnsHeaders>
                <WNSHeader>
                  <Header>X-WNS-Type</Header>
                  <Value>wns/toast</Value>
                </WNSHeader>
              </WnsHeaders>
            </WindowsTemplateRegistrationDescription>
          </content>
        </entry>"
    end

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
