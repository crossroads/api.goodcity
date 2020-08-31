module Goodcity
  module Tasks
    module OrganisationTasks

      module_function

      #
      # Initializes the OrganisationUsers' status to either 'pending' or 'approved'
      #
      #
      def initialize_status_field!
        charity_role = Role.find_by(name: 'Charity')

        return if charity_role.blank?

        count = 0

        ActiveRecord::Base.transaction do
          charity_role.users.find_each do |u|
            organisations_users = u.organisations_users
            closed_orders       = Order.where("created_by_id = (:id) OR submitted_by_id = (:id)", id: u.id).closed

            organisations_users.each do |ou|
              status = OrganisationsUser::Status::PENDING
              status = OrganisationsUser::Status::APPROVED if closed_orders.find { |o| o.organisation_id == ou.organisation_id }.present?

              ou.status = status
              ou.save!
            end

            count += 1
          end
        end

        count
      end

      def restore_charity_roles!
        charity_role = Role.where(name: 'Charity').first_or_create

        OrganisationsUser.find_each { |ou| charity_role.grant(ou.user) }
      end
    end
  end
end
