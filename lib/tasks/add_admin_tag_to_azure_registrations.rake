namespace :azure do
  task add_admin_tag_to_azure_registrations: :environment do
    app_name = ADMIN_APP
    svc = AzureNotificationsService.new('admin')

    User.staff.each do |user|
      res = svc.send(:execute, :get, "tags/user_#{user.id}_#{app_name}/registrations")

      doc = res.body
      newtag = user.permission.name.downcase
      oldtag = Channel.private_channels_for(user, app_name)
      tags = [newtag, oldtag].flatten

      platform = ""
      handle = (doc.match(/FcmRegistrationId>(.*)</) || [])[1]
      if handle.present?
        platform = "fcm"
      else
        handle = (doc.match(/DeviceToken>(.*)</) || [])[1]
        if handle.present?
          platform = "aps"
        end
      end

      svc.send(:register_device, handle, tags, platform) if platform && handle
    end
  end
end
