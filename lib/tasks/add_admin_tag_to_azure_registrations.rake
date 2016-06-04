namespace :goodcity do

  task add_admin_tag_to_azure_registrations: :environment do
    svc = AzureNotificationsService.new

    User.staff.each do |user|
      res = svc.send(:execute, :get, "tags/#{Channel.private(user)}/registrations")

      doc = Nokogiri::XML(res.decoded)

      newtag = user.permission.name.downcase
      oldtag = Channel.private(user)
      oldtag = Channel.add_admin_app_suffix(oldtag)
      tags = [newtag,oldtag]

      platform = ""
      handle = (doc.at_css "GcmRegistrationId")
      if handle.present?
        platform = "gcm"
      else
        handle = (doc.at_css "DeviceToken")
        if handle.present?
          platform = "aps"
        else
          handle = (doc.at_css "ChannelUri")
          if handle.present?
            platform = "wns"
          end
        end
      end
      handle = handle.content.to_s

      svc.send(:register_device, handle, tags, platform)
    end
  end

end
