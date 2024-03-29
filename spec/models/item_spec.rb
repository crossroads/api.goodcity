require 'rails_helper'

RSpec.describe Item, type: :model do
  before { User.current_user = create(:user) }

  it_behaves_like 'paranoid'

  describe 'Associations' do
    it { is_expected.to belong_to :offer }
    it { is_expected.to belong_to :package_type }
    it { is_expected.to belong_to :rejection_reason }
    it { is_expected.to belong_to :donor_condition }
    it { is_expected.to have_many :messages }
    it { is_expected.to have_many :images }
    it { is_expected.to have_many :packages }
  end

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:donor_description).of_type(:text) }
    it { is_expected.to have_db_column(:state).of_type(:string) }
    it { is_expected.to have_db_column(:offer_id).of_type(:integer) }
    it { is_expected.to have_db_column(:package_type_id).of_type(:integer) }
    it { is_expected.to have_db_column(:rejection_reason_id).of_type(:integer) }
    it { is_expected.to have_db_column(:reject_reason).of_type(:string) }
    it { is_expected.to have_db_column(:rejection_comments).of_type(:text) }
  end

  describe "Instance Methods" do
    let!(:offer) { create :offer, state: "submitted" }
    let!(:item)  { create :item, offer: offer }
    let!(:reviewer) { create :user, :reviewer }
    before { User.current_user = reviewer }

    describe "assign_reviewer" do
      it "should update all items of offer" do
        expect{
          item.accept
        }.to change(offer, :reviewed_by).to(reviewer)
        expect(offer.state).to eq("under_review")
      end
    end
  end

  describe "#need_to_persist?" do
    it "should return true for draft item with messages" do
      item = create :item, :with_messages
      expect(item.need_to_persist?).to eq(true)
    end

    it "should return true for accepted item" do
      item = create :item, state: "accepted"
      expect(item.need_to_persist?).to eq(true)
    end

    it "should return true for rejected item" do
      item = create :item, state: "rejected"
      expect(item.need_to_persist?).to eq(true)
    end

    it "should return false for draft item with no messages" do
      item = create :item, state: "draft"
      expect(item.need_to_persist?).to eq(false)
    end
  end

  describe "#remove" do
    it "should soft-delete item and it's messages" do
      item = create :item, :with_messages, :with_packages
      package_count = item.packages.count
      message_count = item.messages.count
      item.remove
      expect(Item.only_deleted.count).to eql(1)
      expect(Message.only_deleted.count).to eql(message_count)
      expect(Package.only_deleted.count).to eql(package_count)
    end

    it "should soft-delete accepted item" do
      item = create :item, state: "accepted"
      expect{
        item.remove
      }.to change(Item.only_deleted, :count).by(1)
    end

    it "should hard-delete submitted item" do
      item = create :item
      expect{
        item.remove
      }.to change(Item, :count).by(-1)
    end
  end

  describe "#send_reject_message" do
    it "should send message to donor with rejection comments" do
      item = create(:item, :rejected, state: "submitted") # with reject attrs
      expect{
        item.reject
      }.to change(item.messages, :count).by(1)
      expect(item.messages.last.body).to eq(item.rejection_comments)
    end
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "#set_description" do
    describe "when item created by Admin" do
      it "should not reset donor_description if present" do
        item = build :item
        expect{
          item.save
        }.to_not change(item, :donor_description)
      end

      it "should set package_type name as donor_description when saved" do
        item = create :item, :draft, package_type: nil
        item.package_type = create :package_type
        item.save
        expect(item.donor_description).to eq(item.package_type.name)
      end

      it "should set packages notes as donor_description when accepted" do
        item = create :item, :draft, :with_packages
        expected_text = item.packages.pluck(:notes).reject(&:blank?).join(" + ")
        User.current_user = create(:user, :reviewer)
        expect{
          item.accept
        }.to change(item, :donor_description).to(expected_text)
      end
    end
  end

  describe "#submit" do
    let(:message) { Message.last }

    it "on item addition for reviewed offer reset its offer's state" do
      offer = create :offer, :reviewed
      User.current_user = offer.created_by
      item = create :item, :draft, offer: offer
      expect{ item.submit }.to change(offer, :state).to("under_review")
      expect(message.messageable).to eq(offer)
    end

    it "on item addition for scheduled offer send message to admin" do
      offer = create :offer, :scheduled
      User.current_user = offer.created_by
      item = create :item, :draft, offer: offer
      expect{ item.submit }.to_not change(offer, :state)
      expect(message.messageable).to eq(offer)
    end
  end

  describe "not_received_packages" do
    it "should return true for non-received packages" do
      item = create :item, :draft, :with_packages
      expect(item.not_received_packages?).to be true
    end

    it "should return true for non-received packages" do
      item = create :item, :with_received_packages, state: :accepted
      expect(item.not_received_packages?).to be false
    end
  end

  context "#shared_packages" do
    before do
      @item = create :item
      @shared_packages = create_list :package, 2, item: @item
      @shared_packages.each{ |pkg| Shareable.publish(pkg) }
    end

    it "should fetch only shared packages from offer" do
      expect(@item.shared_packages.pluck(:id)).to match_array(@shared_packages.pluck(:id))
    end
  end

  context "messages association" do
    let(:donor) { create :user }
    let(:reviewer) { create :user, :reviewer }
    let!(:donor_item) { create :item }
    let!(:donor_messages)  { create_list :message, 3, is_private: false, messageable: donor_item }
    let!(:private_messages) { create_list :message, 3, is_private: true, messageable: donor_item }

    it "for donor fetch non-private messages" do
      User.current_user = donor
      expect(donor_item.messages.count).to eq(3)
      expect(donor_item.messages.pluck(:id)).to match_array(donor_messages.pluck(:id))
      expect(donor_item.messages.pluck(:id)).to_not include(*private_messages.pluck(:id))
    end

    it "for reviewer fetch all messages" do
      User.current_user = reviewer
      expect(donor_item.messages.count).to eq(6)
      expect(donor_item.messages.pluck(:id)).to include(*donor_messages.pluck(:id))
      expect(donor_item.messages.pluck(:id)).to include(*private_messages.pluck(:id))
    end
  end
end
