require 'goodcity/user_utils'
require "rails_helper"

context Goodcity::UserUtils do

  let(:master_user) { create :user }
  let(:other_user) { create :user }

  context "Merge two users into one" do

    context "merge_user!" do
      it "should merge other-user into master-user" do
        master_user.update_attribute(:email, nil)

        Goodcity::UserUtils.merge_user!(master_user, other_user)

        expect(master_user.reload.email).to eq(other_user.email)
        expect{
          User.find(other_user.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "should give error if master_user_id is blank" do
        invalid_id = User.last.id + 1
        response = Goodcity::UserUtils.merge_user!(invalid_id, other_user.id)

        expect(response[:error]).to eq("User #{invalid_id} to be merged into does not exist")
      end

      it "should give error if other_user_id is blank" do
        invalid_id = User.last.id + 1
        response = Goodcity::UserUtils.merge_user!(master_user.id, invalid_id)

        expect(response[:error]).to eq("User #{invalid_id} to be merged does not exist")
      end

      it "should give error if both user-ids are same" do
        response = Goodcity::UserUtils.merge_user!(master_user.id, master_user.id)

        expect(response[:error]).to eq("Please provide different users to perform merge operation.")
      end
    end

    context "reassign_user_details" do
      it "should give precedence to master-user details" do
        master_user_attributes = master_user.attributes
        Goodcity::UserUtils.reassign_user_details(master_user, other_user)

        %W[first_name last_name email mobile preferred_language title other_phone image_id].each do |attribute|
          expect(master_user[attribute]).to eq(master_user_attributes[attribute])
        end
      end

      it "should give precedence to other-user details when master-user details are empty" do
        master_user = create :user, first_name: nil, last_name: nil, email: nil,
                      preferred_language: nil, title: nil, other_phone: nil, image_id: nil
        other_user_attributes = other_user.attributes

        Goodcity::UserUtils.reassign_user_details(master_user, other_user)

        %W[first_name last_name email preferred_language title other_phone image_id].each do |attribute|
          expect(master_user[attribute]).to eq(other_user_attributes[attribute])
        end
      end
    end

    context "reassign_offers" do
      before do
        merged_offers = create_list :offer, 5, created_by: other_user,
          reviewed_by: other_user, closed_by_id: other_user.id, received_by_id: other_user.id
        offers = create_list :offer, 5, created_by: master_user,
          reviewed_by: master_user, closed_by_id: master_user.id, received_by_id: master_user.id
      end

      it "reassign created offers of other-user to master-user" do
        Goodcity::UserUtils.reassign_offers(master_user, other_user)

        expect(other_user.offers.count).to eq(0)
        expect(master_user.offers.count).to eq(10)
      end

      it "reassign reviewed offers of other-user to master-user" do
        Goodcity::UserUtils.reassign_offers(master_user, other_user)

        expect(other_user.reviewed_offers.count).to eq(0)
        expect(master_user.reviewed_offers.count).to eq(10)
      end

      it "reassign closed offers of other-user to master-user" do
        Goodcity::UserUtils.reassign_offers(master_user, other_user)

        expect(Offer.where(closed_by_id: master_user.id).count).to eq(10)
        expect(Offer.where(closed_by_id: other_user.id).count).to eq(0)
      end

      it "reassign received offers of other-user to master-user" do
        Goodcity::UserUtils.reassign_offers(master_user, other_user)

        expect(Offer.where(received_by_id: master_user.id).count).to eq(10)
        expect(Offer.where(received_by_id: other_user.id).count).to eq(0)
      end
    end

    context "reassign_messages" do
      it "reassign sent messages of other-user to master-user" do
        create_list :message, 5, sender: other_user
        create_list :message, 5, sender: master_user

        Goodcity::UserUtils.reassign_messages(master_user, other_user)

        expect(other_user.messages.count).to eq(0)
        expect(master_user.messages.count).to eq(10)
      end

      it "reassign sent messages of other-user to master-user" do
        create_list :message, 5, recipient: other_user
        create_list :message, 5, recipient: master_user

        Goodcity::UserUtils.reassign_messages(master_user, other_user)

        expect(Message.where(recipient_id: other_user.id).count).to eq(0)
        expect(Message.where(recipient_id: master_user.id).count).to eq(10)
      end

      it "reassign subscriptions of other-user to master-user" do
        create_list :subscription, 5, user: other_user
        create_list :subscription, 5, user: master_user

        Goodcity::UserUtils.reassign_messages(master_user, other_user)

        expect(other_user.subscriptions.count).to eq(0)
        expect(master_user.subscriptions.count).to eq(10)
      end
    end

    context "reassign_packages" do
      it "reassign requested_packages of other-user to master-user" do
        create_list :requested_package, 5, user: other_user
        create_list :requested_package, 5, user: master_user

        Goodcity::UserUtils.reassign_packages(master_user, other_user)

        expect(other_user.requested_packages.count).to eq(0)
        expect(master_user.requested_packages.count).to eq(10)
      end
    end

    context "reassign_organisations_users" do
      it "reassign organization of other-user to master-user" do
        other_user_org_1 = create :organisation
        other_user_org_1.users << other_user

        other_user_org_2 = create :organisation
        other_user_org_2.users << [other_user, master_user]

        Goodcity::UserUtils.reassign_organisations_users(master_user, other_user)

        expect(other_user.organisations_users.count).to eq(0)
        expect(master_user.organisations_users.count).to eq(2)
      end
    end

    context "reassign_printers_users" do
      it "reassign organization of other-user to master-user" do
        other_user_printer_1 = create :printer
        other_user_printer_1.users << other_user

        other_user_printer_2 = create :printer
        other_user_printer_2.users << [other_user, master_user]

        Goodcity::UserUtils.reassign_printers_users(master_user, other_user)

        expect(other_user.printers_users.count).to eq(0)
        expect(master_user.printers_users.count).to eq(2)
      end
    end

    context "reassign_roles" do
      it "reassign roles of other-user to master-user" do
        other_user.user_roles.destroy_all
        master_user.user_roles.destroy_all

        other_user_role_1 = create :role
        other_user_role_1.users << other_user

        other_user_role_2 = create :role
        other_user_role_2.users << other_user unless other_user.roles.include?(other_user_role_2)
        other_user_role_2.users << master_user unless master_user.roles.include?(other_user_role_2)

        Goodcity::UserUtils.reassign_roles(master_user, other_user)

        expect(other_user.user_roles.count).to eq(0)
        expect(master_user.user_roles.count).to eq(2)
      end
    end

    context "reassign_user_favourites" do
      it "reassign user-favourites of other-user to master-user" do
        User.current_user = other_user
        package = create :package
        UserFavourite.add_user_favourite(package, persistent: false)
        UserFavourite.add_user_favourite((create :package), persistent: false)

        User.current_user = master_user
        UserFavourite.add_user_favourite(package, persistent: false)

        Goodcity::UserUtils.reassign_user_favourites(master_user, other_user)

        expect(UserFavourite.where(user_id: other_user.id).count).to eq(0)
        expect(UserFavourite.where(user_id: master_user.id).count).to eq(4)
      end
    end

    context "reassign_other_records" do
      it "reassign beneficiary of other-user to master-user" do
        create_list :beneficiary, 5, created_by_id: other_user.id
        create_list :beneficiary, 5, created_by_id: master_user.id

        Goodcity::UserUtils.reassign_other_records(master_user, other_user)

        expect(Beneficiary.where(created_by_id: master_user.id).count).to eq(10)
        expect(Beneficiary.where(created_by_id: other_user.id).count).to eq(0)
      end

      it "reassign company of other-user to master-user" do
        create_list :company, 5, created_by_id: other_user.id, updated_by_id: other_user.id
        create_list :company, 5, created_by_id: master_user.id, updated_by_id: master_user.id

        Goodcity::UserUtils.reassign_other_records(master_user, other_user)

        expect(Company.where(created_by_id: master_user.id).count).to eq(10)
        expect(Company.where(created_by_id: other_user.id).count).to eq(0)
        expect(Company.where(updated_by_id: master_user.id).count).to eq(10)
        expect(Company.where(updated_by_id: other_user.id).count).to eq(0)
      end

      it "reassign goodcity_request of other-user to master-user" do
        create_list :goodcity_request, 5, created_by_id: other_user.id
        create_list :goodcity_request, 5, created_by_id: master_user.id

        Goodcity::UserUtils.reassign_other_records(master_user, other_user)

        expect(GoodcityRequest.where(created_by_id: master_user.id).count).to eq(10)
        expect(GoodcityRequest.where(created_by_id: other_user.id).count).to eq(0)
      end

      it "reassign shareable of other-user to master-user" do
        create_list :shareable, 5, created_by_id: other_user.id
        create_list :shareable, 5, created_by_id: master_user.id

        Goodcity::UserUtils.reassign_other_records(master_user, other_user)

        expect(Shareable.where(created_by_id: master_user.id).count).to eq(10)
        expect(Shareable.where(created_by_id: other_user.id).count).to eq(0)
      end

      it "reassign stocktake of other-user to master-user" do
        create_list :stocktake, 5, created_by_id: other_user.id
        create_list :stocktake, 5, created_by_id: master_user.id

        Goodcity::UserUtils.reassign_other_records(master_user, other_user)

        expect(Stocktake.where(created_by_id: master_user.id).count).to eq(10)
        expect(Stocktake.where(created_by_id: other_user.id).count).to eq(0)
      end

      it "reassign stocktake_revision of other-user to master-user" do
        create_list :stocktake_revision, 5, created_by_id: other_user.id
        create_list :stocktake_revision, 5, created_by_id: master_user.id

        Goodcity::UserUtils.reassign_other_records(master_user, other_user)

        expect(StocktakeRevision.where(created_by_id: master_user.id).count).to eq(10)
        expect(StocktakeRevision.where(created_by_id: other_user.id).count).to eq(0)
      end
    end

    describe "reassign updated_by on subform models" do
      before do
        User.current_user = other_user
        create_list :computer_accessory, 5
        create_list :computer, 5
        create_list :electrical, 5
        create_list :medical, 5

        User.current_user = master_user
        create_list :computer_accessory, 5
        create_list :computer, 5
        create_list :electrical, 5
        create_list :medical, 5

        Goodcity::UserUtils.reassign_other_records(master_user, other_user)
      end

      it "reassign computer_accessory of other-user to master-user" do
        expect(ComputerAccessory.where(updated_by_id: master_user.id).count).to eq(10)
        expect(ComputerAccessory.where(updated_by_id: other_user.id).count).to eq(0)
      end

      it "reassign computer of other-user to master-user" do
        expect(Computer.where(updated_by_id: master_user.id).count).to eq(10)
        expect(Computer.where(updated_by_id: other_user.id).count).to eq(0)
      end

      it "reassign Electrical of other-user to master-user" do
        expect(Electrical.where(updated_by_id: master_user.id).count).to eq(10)
        expect(Electrical.where(updated_by_id: other_user.id).count).to eq(0)
      end

      it "reassign Medical of other-user to master-user" do
        expect(Medical.where(updated_by_id: master_user.id).count).to eq(10)
        expect(Medical.where(updated_by_id: other_user.id).count).to eq(0)
      end
    end

    context "reassign_orders" do
      before do
        merged_orders = create_list :order, 5, created_by: other_user,
          processed_by_id: other_user.id, cancelled_by_id: other_user.id,
          process_completed_by_id: other_user.id, dispatch_started_by_id: other_user.id,
          closed_by_id: other_user.id, submitted_by_id: other_user.id
        orders = create_list :order, 5, created_by: master_user,
          processed_by_id: master_user.id, cancelled_by_id: master_user.id,
          process_completed_by_id: master_user.id, dispatch_started_by_id: master_user.id,
          closed_by_id: master_user.id, submitted_by_id: master_user.id
      end

      it "reassign created orders of other-user to master-user" do
        Goodcity::UserUtils.reassign_orders(master_user, other_user)

        expect(other_user.created_orders.count).to eq(0)
        expect(master_user.created_orders.count).to eq(10)
      end

      it "reassign processed orders of other-user to master-user" do
        Goodcity::UserUtils.reassign_orders(master_user, other_user)

        expect(Order.where(processed_by_id: master_user.id).count).to eq(10)
        expect(Order.where(processed_by_id: other_user.id).count).to eq(0)
      end

      it "reassign cancelled orders of other-user to master-user" do
        Goodcity::UserUtils.reassign_orders(master_user, other_user)

        expect(Order.where(cancelled_by_id: master_user.id).count).to eq(10)
        expect(Order.where(cancelled_by_id: other_user.id).count).to eq(0)
      end

      it "reassign process_completed orders of other-user to master-user" do
        Goodcity::UserUtils.reassign_orders(master_user, other_user)

        expect(Order.where(process_completed_by_id: master_user.id).count).to eq(10)
        expect(Order.where(process_completed_by_id: other_user.id).count).to eq(0)
      end

      it "reassign dispatch_started orders of other-user to master-user" do
        Goodcity::UserUtils.reassign_orders(master_user, other_user)

        expect(Order.where(dispatch_started_by_id: master_user.id).count).to eq(10)
        expect(Order.where(dispatch_started_by_id: other_user.id).count).to eq(0)
      end

      it "reassign closed orders of other-user to master-user" do
        Goodcity::UserUtils.reassign_orders(master_user, other_user)

        expect(Order.where(closed_by_id: master_user.id).count).to eq(10)
        expect(Order.where(closed_by_id: other_user.id).count).to eq(0)
      end

      it "reassign submitted orders of other-user to master-user" do
        Goodcity::UserUtils.reassign_orders(master_user, other_user)

        expect(Order.where(submitted_by_id: master_user.id).count).to eq(10)
        expect(Order.where(submitted_by_id: other_user.id).count).to eq(0)
      end
    end

    context "reassign_versions" do
      it "reassign versions of other-user to master-user" do
        create_list :version, 5, whodunnit: other_user.id
        create_list :version, 5, whodunnit: master_user.id

        Goodcity::UserUtils.reassign_versions(master_user, other_user)

        expect(Version.where(whodunnit: other_user.id).count).to eq(0)
        expect(Version.where(whodunnit: master_user.id).count).to eq(10)
      end
    end
  end
end
