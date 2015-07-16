class AzureNotificationsService
  attr_accessor :app_name

  def initialize(is_admin_app=nil)
    @app_name = is_admin_app ? "admin" : "donor"
  end

  def notify(tags, data)
    tags = tags.join(' || ') if tags.instance_of?(Array)
    send :post, 'messages', body: data.to_json, headers: notify_headers(tags)
  end

  def register_device(handle, tags, platform)
    encoded_url = encoded_url(platform, handle)
    res = encoded_url ? (send :get, "registrations?$filter=#{encoded_url}") : ""

    Nokogiri::XML(res.decoded).css('entry title').each do |n|
      send :delete, "registrations/#{n.content}", headers: {'If-Match'=>'*'}
    end
    res = send :post, 'registrationIDs'
    # Location = https://{namespace}.servicebus.windows.net/{NotificationHub}/registrations/<registrationId>?api-version=2014-09
    regId = res.headers['location'].split('/').last.split('?').first
    send :put, "registrations/#{regId}", body: platform_xml_body(handle, tags, platform)
  end

  def send(method, resource, options = {})
    url = request_url(resource)
    options[:method] = method
    options[:headers] ||= {}
    options[:headers]['Authorization'] = sas_token(url)
    Nestful::Request.new(url, options).execute
  end

  private

  def encoded_url(platform, handle)
    case platform
    when "gcm" then URI::encode("GcmRegistrationId eq '#{handle}'")
    when "aps" then URI::encode("DeviceToken eq '#{handle.upcase}'")
    when "wns" then URI::encode("ChannelUri eq '#{handle}'")
    end
  end

  def platform_xml_body(handle, tags, platform)
    # platform
    # https://msdn.microsoft.com/en-us/library/azure/dn223265.aspx
    case platform
    when "gcm" then gcm_platform_xml(handle, tags)
    when "aps" then aps_platform_xml(handle, tags)
    when "wns" then wns_platform_xml(handle, tags)
    else ""
    end
  end

  def payload
    '"category":"$(category)", "offer_id":"$(offer_id)", "item_id":"$(item_id)", "author_id":"$(author_id)", "is_private":"$(is_private)"'
  end

  def gcm_platform_xml(handle, tags)
    template = "{\"data\":{\"message\":\"$(message)\", #{payload}}}"
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
  end

  def aps_platform_xml(handle, tags)
    template = "{\"aps\":{\"alert\":\"$(message)\",\"badge\":1,\"sound\":\"default\", \"payload\":{#{payload}}}}"
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
  end

  def wns_platform_xml(handle, tags)
    # {} are used for expressions in template - https://msdn.microsoft.com/en-us/library/azure/dn530748.aspx
    # so turning {prop:$(prop)} into {'{prop:' + $(prop) + '}'}
    payload_attr = "{'{#{payload}}'}".gsub(/(\$\([^)]+\))/, "' + \\1 + '").encode(:xml => :attr)
    template =
      "<toast launch=#{payload_attr}>
        <visual>
          <binding template=\"ToastText01\">
            <text id=\"1\">$(message)</text>
          </binding>
        </visual>
      </toast>"

    "<?xml version=\"1.0\" encoding=\"utf-8\"?>
    <entry xmlns=\"http://www.w3.org/2005/Atom\">
      <content type=\"application/xml\">
        <WindowsTemplateRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\">
          <Tags>#{tags.join(', ')}</Tags>
          <ChannelUri>#{handle}</ChannelUri>
          <BodyTemplate><![CDATA[#{template}]]></BodyTemplate>
          <WnsHeaders>
            <WnsHeader>
              <Header>X-WNS-Type</Header>
              <Value>wns/toast</Value>
            </WnsHeader>
          </WnsHeaders>
        </WindowsTemplateRegistrationDescription>
      </content>
    </entry>"
  end

  def notify_headers(tags)
    {
      'ServiceBusNotification-Format' => 'template',
      'ServiceBusNotification-Tags' => tags,
      'Content-Type' => 'application/json;charset=utf-8'
    }
  end

  def request_url(resource)
    sep = resource.include?('?') ? '&' : '?'
    "#{settings['endpoint']}/#{resource}#{sep}api-version=2015-01"
  end

  def sas_token(url, lifetime: 10)
    target_uri = escaped_url(url).downcase
    expires = Time.now.to_i + lifetime
    to_sign = "#{target_uri}\n#{expires}"
    signature = escaped_url(Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', settings['key'], to_sign)))
    "SharedAccessSignature sr=#{target_uri}&sig=#{signature}&se=#{expires}&skn=#{settings['key_name']}"
  end

  def escaped_url(url)
    CGI.escape(url).gsub('+', '%20')
  end

  def settings
    Rails.application.secrets.azure_notifications[@app_name]
  end
end
