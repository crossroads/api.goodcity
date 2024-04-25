class AzureNotificationsService
  #
  # This class interacts with the Azure Notification Hub to
  #   - register mobile devices to recieve notifications
  #   - send notifications to registered devices
  #
  # Registration
  #   - first create a new RegistrationId
  #   - then add a notification template, a device handle and a set of tags to the registration
  #
  # Templates
  #   - templates are used to format the notification message and are platform specific
  #   - aps format: "{\"aps\":{\"alert\":\"$(message)\",\"sound\":\"default\", \"payload\":{#{payload}}}}"
  #
  # Notifications
  #   - notifications are sent to devices that match the tags
  #   - the data is sent in a device independent way and the Notification Hub will inject the variables into the template
  #      and send to the device via APNS or FCM. This saves us from having to code specific messages for each platform.
  #
  # There are 2 platforms for notifications:
  #  - 'fcm' for sending notifications to Android devices
  #  - 'aps' for sending notifications to Apple devices
  #
  # Note:
  #   - Notification subscriptions expire automatically after 90 days
  #   - Whilst we are migrating apps from using fcm to fcmv1 we have code for both here.
  #   - After July 2024, when fcm is turned off, we can remove the relevant 'fcm' code and keep 'fcmv1' code.
  #   - When specified 'platform' is either: 'aps' or 'fcm' (don't use fcmv1). The code will internally call
  #     the correct method and convert from fcm to fcmv1 as required.
  #
  # Example Usage:
  #
  # > svc = AzureNotificationsService.new('admin')
  # svc.send(:execute, :get, "tags/user_#{user.id}_admin/registrations")
  # > svc.notify('user_7_admin', {message: 'Hello', offer_id: 1, item_id: 2, is_private: false})

  def initialize(app_name)
    raise ArgumentError.new("Invalid app_name: #{app_name}") unless APP_NAMES.include?(app_name)
    @app_name = app_name
  end

  # Example Usage:
  # > svc = AzureNotificationsService.new('admin')
  # > svc.notify('user_7_admin', {message: 'Hello', offer_id: 1, item_id: 2, is_private: false})
  #
  def notify(tags, data)
    [tags].flatten.each_slice(20) do |tags|
      execute :post, 'messages', body: update_data(data).to_json, headers: notify_headers(tags.join(' || '))
    end
  end

  # Make this private?
  def delete_existing_registration(platform, handle)
    encoded_url(platform, handle).each do |url|
      res = execute(:get, "registrations?$filter=#{url}")
      Nokogiri::XML(res.decoded).css('entry title').each do |n|
        execute(:delete, "registrations/#{n.content}", headers: {'If-Match'=>'*'})
      end
    end
  end

  # Register Device
  #   - Removes existing registrations for the specified device handle
  #   - Registers the device with the specified tags and platform
  #   - Note: there is one Notification Hub for each app so removing all registrations will only remove all 'admin' registrations or 'stock' registrations.
  #
  # Example Usage:
  # > svc = AzureNotificationsService.new('admin')
  # > handle = "...device handle..."
  # > tags = ["user_7_admin", "reviewer"]
  # > svc.register_device(handle, tags, 'fcm')
  #
  def register_device(handle, tags, platform)
    delete_existing_registration(platform, handle)
    res = execute :post, 'registrationIDs'
    # Location = https://{namespace}.servicebus.windows.net/{NotificationHub}/registrations/<registrationId>?api-version=2014-09
    regId = res.headers['location'].split('/').last.split('?').first
    execute :put, "registrations/#{regId}", body: platform_xml_body(handle, tags, platform)
  end

  private

  # Example Usage:
  #
  # svc = AzureNotificationsService.new('admin')
  # svc.send(:execute, :get, "tags/user_#{user.id}_admin/registrations")
  #
  def execute(method, resource, options = {})
    url = request_url(resource)
    options[:method] = method
    options[:headers] ||= {}
    options[:headers]['Authorization'] = sas_token(url)
    Nestful::Request.new(url, options).execute
  end

  # For FCM this will return search queries for both FcmV1RegistrationId and GcmRegistrationId (legacy)
  # After July 2024, we can remove references to GcmRegistrationId
  def encoded_url(platform, handle)
    case platform
    when "fcm" then [URI::encode("FcmV1RegistrationId eq '#{handle}'"), URI::encode("GcmRegistrationId eq '#{handle}'")]
    when "aps" then [URI::encode("DeviceToken eq '#{handle.upcase}'")]
    end
  end

  def platform_xml_body(handle, tags, platform)
    # platform
    # https://msdn.microsoft.com/en-us/library/azure/dn223265.aspx
    case platform
    when "fcm" then fcm_platform_xml(handle, tags)
    when "aps" then aps_platform_xml(handle, tags)
    else ""
    end
  end

  # When a notification is sent, the data is injected into the payload template in the correct place.
  def payload
    '"category":"$(category)", "offer_id":"$(offer_id)", "order_id":"$(order_id)", "item_id":"$(item_id)", "author_id":"$(author_id)", "is_private":"$(is_private)", "message_id": "$(message_id)", "messageable_id": "$(messageable_id)", "messageable_type": "$(messageable_type)"'
  end

  def update_data(data)
    id = Digest::MD5.new
    id.update "o#{data[:offer_id]}i#{data[:item_id]}#{data[:is_private]}"
    data[:notId] = id.hexdigest.gsub(/[a-zA-Z]/, "")[0..6]

    # strip html tags
    data[:message] = ActionView::Base.full_sanitizer.sanitize(data[:message])
    data
  end

  # Template for Apple devices
  # {
  #   "aps": {
  #     "alert": "$(message)",
  #     "sound": "default",
  #     "payload": {
  #       "category": "$(category)",
  #       "offer_id": "$(offer_id)",
  #       "order_id": "$(order_id)",
  #       "item_id": "$(item_id)",
  #       "author_id": "$(author_id)",
  #       "is_private": "$(is_private)",
  #       "message_id": "$(message_id)",
  #       "messageable_id": "$(messageable_id)",
  #       "messageable_type": "$(messageable_type)"
  #      }
  #    }
  #  }
  def aps_platform_xml(handle, tags)
    template = "{\"aps\":{\"alert\":\"$(message)\",\"sound\":\"default\", \"payload\":{#{payload}}}}"
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>
    <entry xmlns=\"http://www.w3.org/2005/Atom\">
      <content type=\"application/xml\">
        <AppleTemplateRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\">
          <Tags>#{tags.join(',')}</Tags>
          <DeviceToken>#{handle}</DeviceToken>
          <BodyTemplate><![CDATA[#{template}]]></BodyTemplate>
        </AppleTemplateRegistrationDescription>
      </content>
    </entry>"
  end

  # FcmV1TemplateRegistrationDescription. Uses fcmv1 new message format
  #
  # {
  #   "message": {
  #     "data": {
  #       "title": "#{notification_title}",
  #       "message": "$(message)",
  #       "notId": "$(notId)",
  #       "style": "inbox",
  #       "summaryText": "There are %n% notifications.",
  #       "category": "$(category)",
  #       "offer_id": "$(offer_id)",
  #       "order_id": "$(order_id)",
  #       "item_id": "$(item_id)",
  #       "author_id": "$(author_id)",
  #       "is_private": "$(is_private)",
  #       "message_id": "$(message_id)",
  #       "messageable_id": "$(messageable_id)",
  #       "messageable_type": "$(messageable_type)"
  #     }
  #   }
  #  }
  def fcm_platform_xml(handle, tags)
    template = "{\"message\":{\"data\":{\"title\":\"#{notification_title}\", \"message\":\"$(message)\", \"notId\": \"$(notId)\", \"style\":\"inbox\", \"summaryText\":\"There are %n% notifications.\", #{payload} } } }"
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>
    <entry xmlns=\"http://www.w3.org/2005/Atom\">
      <content type=\"application/xml\">
        <FcmV1TemplateRegistrationDescription xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.microsoft.com/netservices/2010/10/servicebus/connect\">
          <Tags>#{tags.join(',')}</Tags>
          <FcmV1RegistrationId>#{handle}</FcmV1RegistrationId>
          <BodyTemplate><![CDATA[#{template}]]></BodyTemplate>
        </FcmV1TemplateRegistrationDescription>
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
    "#{settings[:endpoint]}/#{resource}#{sep}api-version=2015-01"
  end

  def sas_token(url, lifetime: 10)
    target_uri = escaped_url(url).downcase
    expires = Time.now.to_i + lifetime
    to_sign = "#{target_uri}\n#{expires}"
    signature = escaped_url(Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', settings[:key], to_sign)))
    "SharedAccessSignature sr=#{target_uri}&sig=#{signature}&se=#{expires}&skn=#{settings[:key_name]}"
  end

  def escaped_url(url)
    CGI.escape(url).gsub('+', '%20')
  end

  # Retreive settings for the correct Notification Hub
  def settings
    Rails.application.secrets.azure_notifications[@app_name.to_sym]
  end

  def notification_title
    # TODO i18n for title
    prefix = Rails.env.production? ? "" : "S. "
    suffix = @app_name == DONOR_APP ? '' : " #{@app_name.titleize}"
    "#{prefix}GoodCity#{suffix}"
  end
end
