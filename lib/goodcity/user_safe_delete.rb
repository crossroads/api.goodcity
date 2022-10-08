#
# Safely remove a user at their request
#
# Should generally be run as a background task
#
# Conditions:
#   - User account must not have any 'in progress' offers
#   - User account must not have any 'in progress' orders
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
#
#
# TODO
#
#   This deletion mechanism has to eventually work for all apps.
#   For now, don't allow previous admins or stock users to be deleted
#
# For later
#   Admin / Stock app users wanting to be deleted should
#     - retain their name in User record (delete mobile, email etc)
#     - don't delete message content created when in admin role
#     - 


module Goodcity
  class UserSafeDelete

    def initialize(user)
      @user = user
    end

    def can_delete
      # returns
      #   { result: true, reason: "OK" }
      #   { result: false, reason: "User has active offers" }
      #
      # are all offers draft, cancelled, or resolved?
      # any orders?
      # user has never used admin or stock apps (we must retain admin generated content)
      return { result: false, reason: "User has active offers" } if Offer.where(created_by_id: @user.id).where.not( state: %w(draft cancelled closed inactive) ).any?
      return { result: false, reason: "User has orders" } if Order.where(created_by_id: @user.id).any?
      return { result: false, reason: "User has roles" } if @user.roles.any?
      
      return { result: true, reason: "OK" }
    end
    
    def delete!
      User.transaction do
        if can_delete
          delete_user_data
          delete_messages
          delete_organisations_users
          delete_images
          delete_contacts
          delete_associations
        end
      end
    end
  
    private

    def delete_user_data
      attributes = {
        title: nil, first_name: "Deleted", last_name: "User",
        mobile: nil, other_phone: nil, email: nil,
        disabled: true, is_mobile_verified: false,
        is_email_verified: false, receive_email: false
      }
      byebug
      @user.image&.destroy
      @user.update(attributes)
      
    end

    def delete_messages
      # Set all message body content to '<message deleted>'
      #   caveat: don't obfsucate messages user sent if they were a reviewer or supervisor or stock app user
      # and all message versions
    end

    def delete_organisations_users
      # Set status to expired
      # Set preferred_contact_number to blank
      # Set position to empty
    end

    def delete_images
      # only delete item/package images this user created
      #   caveat: don't delete images uploaded as an admin or stock user
      # use versions to determine image owner and whether it was on an offer
      # delete versions also
    end

    def delete_contacts
      # Find contacts derived from address, order_transports, and delivery records
      # Set name to "Deleted contact"
      # Set mobile to blank
      # Remove associated versions
    end

    def delete_associations
      # Straight up removal
      # Find addresses derived from order_transports and orders
      # Find auth_tokens, printers_users, user_favorites, user_roles
      # and versions for all the above
    end

  end
end
