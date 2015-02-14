require 'rails_helper'

RSpec.describe Item, type: :model do

  it_behaves_like 'paranoid'

  describe 'Associations' do
    it { is_expected.to belong_to :offer }
    it { is_expected.to belong_to :item_type }
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
    it { is_expected.to have_db_column(:item_type_id).of_type(:integer) }
    it { is_expected.to have_db_column(:rejection_reason_id).of_type(:integer) }
    it { is_expected.to have_db_column(:reject_reason).of_type(:string) }
    it { is_expected.to have_db_column(:rejection_comments).of_type(:string) }
    it { is_expected.to have_db_column(:saleable).of_type(:boolean) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:donor_condition_id) }
  end

  describe 'Scope Methods' do
    let!(:item)    { create :item }
    let!(:an_item) { create :item } # this item should not be changed

    describe 'update_saleable' do
      it 'should update all items of offer' do
        expect{
          item.update_saleable
        }.to change(Item.where(saleable: true), :count).by(1)
        expect(an_item).to_not be_saleable
      end
    end
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
    it "should return true for item with messages" do
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
  end

  describe "#remove" do
    it "should soft-delete item with messages" do
      item = create :item, :with_messages
      expect{
        item.remove
      }.to change(Item.only_deleted, :count).by(1)
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
      expect_any_instance_of(Message).to receive(:update_client_store)
      expect_any_instance_of(Message).to receive(:send_new_message_notification)

      item = create(:item, :rejected, state: "submitted") # with reject attrs
      expect{
        item.reject
      }.to change(item.messages, :count).by(1)
      expect(item.messages.last.body).to eq(item.rejection_comments)
    end
  end
end
