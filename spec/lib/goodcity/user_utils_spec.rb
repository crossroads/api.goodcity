require 'goodcity/user_utils'
require "rails_helper"

context Goodcity::UserUtils do

  let(:master_user) { create :user }
  let(:other_user) { create :user }

  context "Merge two users into one" do

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

  end

end
