require 'rails_helper'

context Goodcity::UserSafeDelete do

  let(:user) { create(:user) }

  before(:each) { PaperTrail.request.whodunnit = user.id }

  context 'can_delete' do

    subject { Goodcity::UserSafeDelete.new(user) }

    context 'returns true if all offers in terminal states' do
      before(:each) do
        create(:offer, state: "draft", created_by: user)
        create(:offer, state: "closed", created_by: user)
      end
      it { expect(subject.can_delete[:result]).to eql(true) }
    end

    context 'returns false if at least one submitted offer' do
      before(:each) do
        create(:offer, state: "submitted", created_by: user)
        create(:offer, state: "closed", created_by: user)
      end
      it do
        expect(subject.can_delete[:result]).to eql(false)
        expect(subject.can_delete[:reason]).to eql("We're sorry but we're unable to delete your account because you have an active offer. Please close or cancel it first. If you have any questions, please in-app message us and we will assist you.")
      end
    end

    context 'returns true if no orders' do
      it { expect(subject.can_delete[:result]).to eql(true) }
    end

    context 'returns false if at least one order' do
      before(:each) do
        create(:order, created_by: user)
      end
      it do
        expect(subject.can_delete[:result]).to eql(false)
        expect(subject.can_delete[:reason]).to eql("We're sorry but we're unable to delete your account because you have an active order. Please close or cancel it first. If you have any questions, please in-app message us and we will assist you.")
      end
    end

    context "returns false if user has the system user role" do
      let(:user) { create(:user, :system )}
      it do
        expect(subject.can_delete[:result]).to eql(false)
        expect(subject.can_delete[:reason]).to eql("System users cannot be deleted.")
      end
    end

    context "returns false if trying to delete app_store user" do
      let(:user) { create(:user, mobile: ENV['APPSTORE_REVIEWER_LOGIN_NUMBER']) }
      it do
        expect(subject.can_delete[:result]).to eql(false)
        expect(subject.can_delete[:reason]).to eql("App Store Reviewer account cannot be deleted.")
      end
    end

  end

  context 'hard_delete!' do

    let(:image) { create(:image) }
    let(:user) { create(:user, title: "Mr", first_name: "Bob", last_name: "Jones",
      mobile: "+85252341678", other_phone: "+85287654321", email: "email@example.com",
      image_id: image.id, disabled: false, is_mobile_verified: true,
      is_email_verified: true, receive_email: true) }

    context "user data" do
      it do
        image_id = user.image_id # so we can check later that it's been deleted
        Goodcity::UserSafeDelete.new(user).delete!
        expect(user.title).to eql(nil)
        expect(user.first_name).to eql("Deleted")
        expect(user.last_name).to eql("User")
        expect(user.mobile).to eql(nil)
        expect(user.other_phone).to eql(nil)
        expect(user.email).to eql(nil)
        expect(user.disabled).to eql(true)
        expect(user.is_mobile_verified).to eql(false)
        expect(user.is_email_verified).to eql(false)
        expect(user.receive_email).to eql(false)
        expect(user.image_id).to eql(nil)
        expect(Image.find_by_id(image_id)).to eql(nil)
      end
    end

    context "message data" do
      let!(:message1) { create(:message, sender: user, body: 'message 1') }
      let!(:message2) { create(:message, sender: create(:user), body: 'message 2') }
      let!(:message3) { create(:message, sender: user, body: 'message 3', is_private: true) }
      with_versioning do
        it do
          Goodcity::UserSafeDelete.new(user).delete!
          expect(message1.reload.body).to eql("<message deleted>")
          expect(Version.where(item: message1).count).to be > 0
          Version.where(item: message1).each do |version|
            if version.object && version.object['body']
              [version.object["body"]].flatten.compact.each do |msg|
                expect(msg).to eql("<message deleted>")
              end
            end
            if version.object_changes && version.object_changes['body']
              version.object_changes["body"].compact.each do |msg|
                expect(msg).to eql("<message deleted>")
              end
            end
          end
          # message 2 and 3 should be unaltered
          expect(message2.reload.body).to eql("message 2")
          Version.where(item: message2, event: "create").each do |version|
            expect(version.object_changes["body"].last).to eql('message 2')
          end
          expect(message3.reload.body).to eql("message 3")
        end
      end
    end

    context "organisations user" do
      let!(:organisations_user) { create(:organisations_user, :approved, user_id: user.id, position: 'CEO', preferred_contact_number: '12345678') }
      it do
        Goodcity::UserSafeDelete.new(user).delete!
        record = user.organisations_users.first
        expect(record.status).to eql(OrganisationsUser::Status::EXPIRED)
        expect(record.position).to eql(nil)
        expect(record.preferred_contact_number).to eql(nil)
      end
    end

    context "delete images" do
      let(:offer1) { create(:offer, :with_items, created_by: user) }
      let(:offer2) { create(:offer, :with_items, created_by: create(:user)) }
      with_versioning do # we use version.whodunnit to determine which images belong to the user
        it do
          images1 = offer1.images.pluck(:id)
          images2 = offer2.images.pluck(:id)
          Goodcity::UserSafeDelete.new(user).delete!
          expect(Image.unscoped.where(id: images1).size).to eql(0)
          expect(images2.size).to be > 0
          expect(Image.unscoped.where(id: images2).size).to eql(images2.size)
        end
      end
    end

    context "delete contacts" do
      let(:offer) { create(:offer, created_by: user) }
      let!(:delivery) { create(:gogovan_delivery, offer: offer) }
      with_versioning do
        it do
          contact = offer.delivery.contact
          expect(contact.name).to_not eql("Deleted contact")
          Goodcity::UserSafeDelete.new(user).delete!
          contact.reload
          expect(contact.name).to eql("Deleted contact")
          expect(Version.where(item: contact).count).to be > 0
          Version.where(item: contact).each do |version|
            if version.object && version.object['name']
              [version.object["name"]].flatten.compact.each do |msg|
                expect(msg).to eql("Deleted contact")
              end
            end
            if version.object_changes && version.object_changes['name']
              version.object_changes["name"].compact.each do |msg|
                expect(msg).to eql("Deleted contact")
              end
            end
          end
        end
      end
    end

    context "delete_associations" do
      before(:each) do
        create(:auth_token, user: user)
        create(:printers_user, user: user)
        create(:user_favourite, user: user)
      end

      it do
        expect(user.auth_tokens.size).to be > 0
        expect(user.printers_users.size).to be > 0
        expect(UserFavourite.where(user: user).size).to be > 0
        Goodcity::UserSafeDelete.new(user).delete!
        expect(user.auth_tokens.count).to be == 0
        expect(user.printers_users.size).to be == 0
        expect(UserFavourite.where(user: user).size).to be == 0
      end

    end

  end

  context "soft_delete!" do
    let(:image) { create(:image) }
    let(:user) { create(:user, :reviewer, title: "Mr", first_name: "Bob", last_name: "Jones",
      mobile: "+85252341678", other_phone: "+85287654321", email: "email@example.com",
      image_id: image.id, disabled: false, is_mobile_verified: true,
      is_email_verified: true, receive_email: true) }

    context "user data should not remove name" do
      it do
        image_id = user.image_id # so we can check later that it's been deleted
        Goodcity::UserSafeDelete.new(user).delete!
        expect(user.title).to eql("Mr")
        expect(user.first_name).to eql("Bob")
        expect(user.last_name).to eql("Jones")
        expect(user.mobile).to eql(nil)
        expect(user.other_phone).to eql(nil)
        expect(user.email).to eql(nil)
        expect(user.disabled).to eql(true)
        expect(user.is_mobile_verified).to eql(false)
        expect(user.is_email_verified).to eql(false)
        expect(user.receive_email).to eql(false)
        expect(user.image_id).to eql(nil)
        expect(Image.find_by_id(image_id)).to eql(nil)
      end
    end

    context "should not delete message data" do
      let!(:message1) { create(:message, sender: user, body: 'message 1') }
      with_versioning do
        it do
          Goodcity::UserSafeDelete.new(user).delete!
          expect(message1.reload.body).to eql("message 1")
        end
      end
    end

  end

  describe '#should_soft_delete?' do

    subject { Goodcity::UserSafeDelete.new(user) }

    context 'when user has roles' do
      let(:user) { create(:user, :reviewer) }

      it 'returns true' do
        expect(subject.send("should_soft_delete?")).to be true
      end
    end

    context 'when user has Package versions' do
      before { create(:version, whodunnit: user.id, item_type: 'Package') }

      it 'returns true' do
        expect(subject.send("should_soft_delete?")).to be true
      end
    end

    context 'when user has reviewed offers' do
      before { create(:offer, reviewed_by: user) }

      it 'returns true' do
        expect(subject.send("should_soft_delete?")).to be true
      end
    end

    context 'when user has processed orders' do
      before { create(:order, processed_by: user) }

      it 'returns true' do
        expect(subject.send("should_soft_delete?")).to be true
      end
    end

    context 'when user does not have any associated roles, versions, offers, or orders' do
      it 'returns false' do
        expect(subject.send("should_soft_delete?")).to be false
      end
    end
  end
end