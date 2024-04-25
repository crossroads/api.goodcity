#
# Safely remove a user at their request
#
# Should generally be run as a background task
# > UserSafeDeleteJob.perform_later(user_id)
#
# Conditions:
#   - User account must not have any 'in progress' offers
#   - User account must not have any 'in progress' orders
#   - User must not be a system user
#   - User must not be the app store reviewer
#
# Deletion:
#   - user profile (obfuscated or fields erased)
#   - message body text replaced with '<message deleted>'
#   - organisations links expired and personal data erased
#   - obfuscate contact records
#   - address, auth_tokens, printers_users deleted
#   - images, user_favorites, user_roles deleted
#   - version records of the above are deleted
#
# Exclusions
#
#   - the offer, item, packages, deliveries, schedule records etc are kept as this is the donation record and there is no personal data in there
#   - Admin / Stock app administrative users wanting to be deleted should
#     - retain their name in User record (delete mobile, email etc)
#     - don't delete message content created when in admin role
#

module Goodcity
  class UserSafeDelete

    def initialize(user)
      @app_store_mobile = Rails.application.secrets.appstore_reviewer_login&.fetch(:number) # nil if doesn't exist
      @user = user
      raise "User must exist" unless @user.is_a?(User)
    end

    def can_delete
      # Returns one of:
      #   { result: true, reason: "OK" }
      #   { result: false, reason: "..." }
      #
      return { result: false, reason: I18n.t('user_safe_delete.user_has_active_offers') } if Offer.where(created_by_id: @user.id).where.not( state: %w(draft cancelled closed inactive) ).any?
      return { result: false, reason: I18n.t('user_safe_delete.user_has_active_orders') } if Order.where(created_by_id: @user.id).any?
      return { result: false, reason: "System users cannot be deleted."} if @user.system_user?
      return { result: false, reason: "App Store Reviewer account cannot be deleted."} if @app_store_mobile.present? and (@user.mobile == @app_store_mobile)
      return { result: true, reason: "OK" }
    end

    # can_delete returns true/false without giving a reason
    def can_delete?
      can_delete[:result]
    end

    def delete!
      User.transaction do
        raise "User doesn't exist!" unless User.find(@user.id)
        if can_delete?
          if should_soft_delete?
            delete_user_data(hard: false)
          else
            delete_user_data(hard: true)
            delete_messages
          end
          delete_organisations_users
          delete_images
          delete_contacts
          delete_associations
        end
      end
    end

    private

    # If user has ever held an administrative role then we should soft delete
    def should_soft_delete?
      @user.roles.any? ||
        Version.where(whodunnit: @user.id, item_type: %w(Package OrdersPackage)).any? ||
        Offer.where(reviewed_by_id: @user.id).any? ||
        Offer.where(received_by_id: @user.id).any? ||
        Offer.where(closed_by_id: @user.id).any? ||
        Order.where(processed_by_id: @user.id).any? ||
        Order.where(process_completed_by_id: @user.id).any? ||
        Order.where(dispatch_started_by_id: @user.id).any? ||
        Order.where(closed_by_id: @user.id).any? ||
        Order.where(cancelled_by_id: @user.id).any?
    end

    # soft delete will retain user's name and obfuscate other fields
    def delete_user_data(hard: false)
      attributes = {
        mobile: nil, other_phone: nil, email: nil,
        disabled: true, is_mobile_verified: false,
        is_email_verified: false, receive_email: false,
        image: nil
      }
      attributes = attributes.merge(title: nil, first_name: "Deleted", last_name: "User") if hard == true
      image_id = @user.image_id
      @user.update(attributes)
      Image.find(image_id)&.really_destroy! if image_id.present?
    end

    def delete_messages
      # Set all message body content to '<message deleted>'
      # Don't obfsucate messages user sent if they were a reviewer or supervisor or stock app user
      # Also update message text in versions
      Message.where(sender: @user).where(is_private: false).each do |msg|
        msg.update(body: "<message deleted>")
        Version.where(item: msg).each do |version|
          body = version.object && version.object["body"]
          if body.is_a?(String) && !body.blank?
            version.object["body"] = "<message deleted>"
          elsif body.is_a?(Array) && !body.empty?
            version.object["body"].map!{|text| "<message deleted>" unless text.blank?}
          end
          lookup = version.object && version.object["lookup"]
          if lookup.is_a?(String) && !lookup.blank?
            version.object["lookup"] = "{}"
          elsif lookup.is_a?(Array) && !lookup.empty?
            version.object["lookup"] = ["{}", {}]
          end
          if version.object_changes && version.object_changes['body'].is_a?(Array)
            version.object_changes["body"].map!{|x| "<message deleted>" unless x.blank?}
          end
          version.save
        end
      end
    end

    def delete_organisations_users
      OrganisationsUser.where(user: @user).update(
        status: OrganisationsUser::Status::EXPIRED,
        preferred_contact_number: nil,
        position: nil
      )
    end

    def delete_images
      # only delete item/package images on offers that this user created
      #   caveat: don't delete images uploaded as an admin or stock user
      # use versions to determine image owner and whether it was on an offer
      offer_ids = Offer.where(created_by: @user).pluck(:id)
      Image.unscoped.joins(:versions).where(versions: { related_type: 'Offer', related_id: offer_ids, whodunnit: @user.id} ).each do |image|
        image.really_destroy!
      end
    end

    def delete_contacts
      # Find contacts derived from address, order_transports, and delivery records
      # Set name to "Deleted contact"
      # Set mobile to blank
      # Update associated versions
      # We need to keep delivery addresses for donation purposes
      #
      # order.order_transports.contact
      Contact.unscoped.where(delivery: { offer_id: @user.offers.pluck(:id) }).
        joins("INNER JOIN deliveries delivery ON delivery.contact_id = contacts.id").each do |contact|
        contact.update(name: "Deleted contact", mobile: nil)
        contact.versions.each do |version|
          name = version.object && version.object["name"]
          if name.is_a?(String) && !name.blank?
            version.object["name"] = "Deleted contact"
          elsif name.is_a?(Array) && !name.empty?
            version.object["name"].map!{|text| "Deleted contact" unless text.blank?}
          end
          if version.object_changes && version.object_changes['name'].is_a?(Array)
            version.object_changes["name"].map!{|x| "Deleted contact" unless x.blank?}
          end
          version.save
        end
      end
    end

    def delete_associations
      AuthToken.where(user: @user).destroy_all
      PrintersUser.where(user: @user).destroy_all
      UserFavourite.where(user: @user).destroy_all
      UserRole.where(user: @user).destroy_all
    end

  end
end
