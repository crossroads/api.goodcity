# frozen_string_literal: true

class ResyncDuplicateUsers
  def self.apply
    # 1. Fetch the users with duplicate email
    sql = "SELECT id, email FROM users
          WHERE email IS NOT NULL AND
                email != '' AND
                UPPER(email) IN (SELECT UPPER(email) FROM users GROUP BY UPPER(email) HAVING COUNT(*) > 1)
          ORDER BY email, id"
    duplicate_users = User.find_by_sql(sql)
    # 2. Create a hash of user email as key and the ids as values
    # Do this only for charity user
    user_hash = {}
    duplicate_users.map do |user|
      _user = User.find(user.id)
      if _user.roles.map(&:name).uniq == ['Charity']
        email = user.email.downcase
        if !user_hash[email]
          user_hash[email] = [user.id]
        else
          user_hash[email] << user.id
        end
      end
    end

    # 3. Iterate over the hash and find the orders from duplicate account.
    # Attach it to the account where user email is in lower case
    user_hash.each do |k, v|
      orders = []
      original_user_id = nil

      v.map do |id|
        user = User.find(id)
        if user.email != k
          orders << Order.where(created_by_id: user.id)
        else
          original_user_id = id
        end
      end

      orders.map do |order|
        order.map { |o| o.update(created_by_id: original_user_id) }
        order.map { |m| m.messages.where(sender_id: v).update_all(sender_id: original_user_id) }
        order.map { |s| s.subscriptions.where(user_id: v).update_all(user_id: original_user_id) }
      end

      # 4. delete duplicate users
      user_ids_to_delete = [v] - [original_user_id]
      user_ids_to_delete.flatten.map { |id| User.find(id).destroy }
    end
  end
end
