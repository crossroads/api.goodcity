require 'rails_helper'

context Goodcity::UserSafeDelete do

  let(:user) { create(:user) }
  subject { Goodcity::UserSafeDelete.new(user) }

  context 'can_delete' do

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
        expect(subject.can_delete[:reason]).to eql("User has active offers")
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
        expect(subject.can_delete[:reason]).to eql("User has orders")
      end
    end

    context "returns true if user doesn't have any roles" do
      it do
        expect(user.roles.size).to eql(0)
        expect(subject.can_delete[:result]).to eql(true)
      end
    end

    context "returns false if user has at leats one role" do
      let(:user) { create(:user, :order_administrator )}
      it do
        expect(subject.can_delete[:result]).to eql(false)
        expect(subject.can_delete[:reason]).to eql("User has roles")
      end
    end

  end

  context 'delete!' do

    let(:image) { create(:image) }
    let(:user) { create(:user, title: "Mr", first_name: "Bob", last_name: "Jones",
      mobile: "+85252341678", other_phone: "+85287654321", email: "email@example.com",
      image_id: image.id, disabled: false, is_mobile_verified: true,
      is_email_verified: true, receive_email: true) }

    context "user data" do
      it do
        Goodcity::UserSafeDelete.new(user).delete!
        expect(user.title).to eql(nil)
        expect(user.first_name).to eql("Deleted")
        expect(user.last_name).to eql("User")
        expect(user.mobile).to eql(nil)
        expect(user.other_phone).to eql(nil)
        expect(user.email).to eql(nil)
        expect(user.image_id).to eql(nil)
        expect(user.disabled).to eql(true)
        expect(user.is_mobile_verified).to eql(false)
        expect(user.is_email_verified).to eql(false)
        expect(user.receive_email).to eql(false)
      end
    end

  end

end
