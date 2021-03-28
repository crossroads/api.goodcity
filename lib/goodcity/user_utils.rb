module Goodcity
  class UserUtils
    def self.merge_user!(master_user_id, other_user_id)
      master_user = User.find_by(id: master_user_id)
      other_user = User.find_by(id: other_user_id)

      if master_user && other_user
        self.reassign_roles(master_user, other_user)

        self.reassign_offers(master_user, other_user)
        self.reassign_messages(master_user, other_user)

        self.reassign_organisations_users(master_user, other_user)
        self.reassign_orders(master_user, other_user)
        self.reassign_packages(master_user, other_user)

        self.reassign_printers_users(master_user, other_user)
        self.reassign_user_favourites(master_user, other_user)

        self.reassign_other(master_user, other_user)

        self.remove_unused_records(other_user)
        self.reassign_versions(master_user, other_user)

        other_user.destroy!
      end
    end

    def self.reassign_offers(master_user, other_user)
      other_user.offers.update(created_by_id: master_user.id)
      other_user.reviewed_offers.update(reviewed_by_id: master_user.id)

      offer_columns = %w(closed_by_id received_by_id)

      offer_columns.each do |column|
        Offer.where(column.to_sym => other_user.id).update(column.to_sym => master_user.id)
      end
    end

    def self.reassign_messages(master_user, other_user)
      other_user.messages.update(sender_id: master_user.id)
      other_user.subscriptions.update(user_id: master_user.id)

      Message.where(recipient_id: other_user.id).update(recipient_id: master_user.id)
    end

    def self.reassign_packages(master_user, other_user)
      other_user.requested_packages.update(user_id: master_user.id)
    end

    def self.reassign_organisations_users(master_user, other_user)
      master_user_organisations = master_user.organisations
      other_user.organisations.each do |organisation|
        master_user.organisations << organisation unless master_user_organisations.include?(organisation)
      end

      other_user.organisations_users.delete_all
    end

    def self.reassign_printers_users(master_user, other_user)
      master_user_printers = master_user.printers
      other_user.printers.each do |printer|
        master_user.printers << printer unless master_user_printers.include?(printer)
      end

      other_user.printers_users.delete_all
    end

    def self.reassign_user_favourites(master_user, other_user)
      master_user_favourites = UserFavourite.where(user_id: master_user.id)

      UserFavourite.where(user_id: other_user.id).each do |record|
        match_record = master_user_favourites.find_by(
          favourite_type: record.favourite_type,
          favourite_id: record.favourite_id)

        if match_record.blank?
          UserFavourite.create(
            user: master_user,
            favourite_id: record.favourite_id,
            favourite_type: record.favourite_type,
            updated_at: Time.current
          )
        end
      end
    end

    def self.reassign_roles(master_user, other_user)
      master_user_roles = master_user.roles
      other_user.roles.each do |role|
        master_user.roles << role unless master_user_roles.include?(role)
      end

      other_user.user_roles.delete_all
    end

    def self.reassign_orders(master_user, other_user)
      other_user.created_orders.update(created_by_id: master_user.id)

      order_columns = %w(processed_by_id cancelled_by_id process_completed_by_id dispatch_started_by_id closed_by_id submitted_by_id)

      order_columns.each do |column|
        Order.where(column.to_sym => other_user.id).update(column.to_sym => master_user.id)
      end
    end

    def self.reassign_other(master_user, other_user)
      user_added_models = %w(Beneficiary Company GoodcityRequest Shareable StocktakeRevision Stocktake)

      # Update created_by
      user_added_models.each do |model|
        model.constantize.where(created_by_id: other_user.id).update(created_by_id: master_user.id)
      end

      user_updated_models = %w(Company ComputerAccessory Computer Electrical Medical OrdersPackage)

      # Update updated_by
      user_updated_models.each do |model|
        model.constantize.where(updated_by_id: other_user.id).update(updated_by_id: master_user.id)
      end
    end

    def self.remove_unused_records(other_user)
      AuthToken.where(user_id: other_user.id).delete_all
      other_user.address.destroy
    end

    def self.reassign_versions(master_user, other_user)
      Version.where(whodunnit: other_user.id).update(whodunnit: master_user.id)
    end

  end
end
