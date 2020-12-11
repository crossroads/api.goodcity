# frozen_string_literal: true

class ResyncDuplicateUsers
  def self.apply
    # 1. Fetch the users with duplicate email
    duplicate_users = User.where("email IS NOT NULL AND email != '' AND UPPER(email) IN (SELECT UPPER(email) FROM users GROUP BY UPPER(email) HAVING COUNT(*) > 1)").order('email, id')

    # 2. Create a hash of user email as key and the ids as values
    # Do this only for charity user
    user_hash = {}
    duplicate_users.map do |user|
      is_charity_user = user.roles.count.zero? && user.active_organisations.count.positive?
      if is_charity_user
        email = user.email.downcase
        user_hash[email] ||= []
        user_hash[email] << user
      end
    end

    # 3. Iterate over the hash and find the orders from duplicate account.
    # Attach it to the account where user email is in lower case
    user_hash.each do |email, users|
      original_user = users.find { |u| u.email == email } || users.first
      bad_users = users.reject { |u| u == original_user }
      bad_ids = bad_users.map(&:id)

      ActiveRecord::Base.transaction do
        Order.where(created_by_id: bad_ids).each do |order|
          order.update(created_by_id: original_user.id)
          order.messages.where(sender_id: bad_ids).update_all(sender_id: original_user.id)
          order.messages.where(recipient_id: bad_ids).update_all(recipient_id: original_user.id)
          order.subscriptions.where(user_id: bad_ids).update_all(user_id: original_user.id)
        end
  
        # 4. delete bad organisations_users records
        organisations_users         = OrganisationsUser.where(user_id: bad_ids)
        original_organisations_user = original_user.organisations_users.first || organisations_users.first

        organisations_users
          .select { |ou| ou != original_organisations_user }
          .each(&:destroy!)

        original_organisations_user&.update(user_id: original_user.id)

        # 5. delete duplicate users
        User.where(id: bad_ids).destroy_all
      end
    end
  end
end
