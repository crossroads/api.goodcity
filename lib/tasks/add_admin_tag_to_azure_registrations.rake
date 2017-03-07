namespace :azure do

  task add_admin_tag_to_azure_registrations: :environment do
    svc = AzureNotificationsService.new

    User.staff.each do |user|
      res = svc.send(:execute, :get, "tags/user_#{user.id}_admin/registrations")

      doc = res.body
      newtag = user.permission.name.downcase
      oldtag = Channel.private(user)
      oldtag = Channel.add_admin_app_suffix(oldtag)
      tags = [newtag,oldtag].flatten

      platform = ""
      handle = (doc.match(/GcmRegistrationId>(.*)</)|| [])[1]
      if handle.present?
        platform = "gcm"
      else
        handle = (doc.match(/DeviceToken>(.*)</) || [])[1]
        if handle.present?
          platform = "aps"
        else
          handle = (doc.match(/ChannelUri>(.*)</) || [])[1]
          platform = "wns" if handle.present?
        end
      end

      svc.send(:register_device, handle, tags, platform) if platform && handle
    end
  end

end
