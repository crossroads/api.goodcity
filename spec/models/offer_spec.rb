require "rails_helper"

RSpec.describe Offer, type: :model do

  before { allow_any_instance_of(PushService).to receive(:notify) }
  let(:offer) { create :offer }

  it_behaves_like "paranoid"

  describe "Associations" do
    it { should belong_to :created_by }
    it { should have_many :messages }
    it { should have_many :items }
  end

  describe "Database Columns" do
    it { should have_db_column(:language).of_type(:string) }
    it { should have_db_column(:state).of_type(:string) }
    it { should have_db_column(:origin).of_type(:string) }
    it { should have_db_column(:stairs).of_type(:boolean) }
    it { should have_db_column(:parking).of_type(:boolean) }
    it { should have_db_column(:estimated_size).of_type(:string) }
    it { should have_db_column(:notes).of_type(:text) }
    it { should have_db_column(:created_by_id).of_type(:integer) }

    it { should have_db_column(:submitted_at).of_type(:datetime) }
    it { should have_db_column(:reviewed_at).of_type(:datetime) }
    it { should have_db_column(:review_completed_at).of_type(:datetime) }
    it { should have_db_column(:received_at).of_type(:datetime) }
  end

  describe "validations" do
    it do
      should validate_inclusion_of(:language).
        in_array( I18n.available_locales.map(&:to_s) )
    end
  end

  it "should set submitted_at when submitted" do
    expect( offer.submitted_at ).to be_nil
    offer.update_attributes(state_event: "submit")
    expect( offer.submitted_at ).to_not be_nil
  end

  describe "Class Methods" do
    describe "valid_state?" do
      it "should verify state valid or not" do
        expect(Offer.valid_state?("submitted")).to be true
        expect(Offer.valid_state?("submit")).to be false
      end
    end

    describe "valid_states" do
      it "should return list of valid states" do
        expect(Offer.valid_states).to include("draft")
        expect(Offer.valid_states).to include("submitted")
      end
    end

    describe "review_by" do
      it "should return offers reviewed by current reviewer" do
        reviewer = create :user, :reviewer
        offer = create :offer, reviewed_by: reviewer
        expect(Offer.review_by(reviewer.id)).to include(offer)
      end
    end
  end

  describe 'assign_reviewer' do
    it 'should assign reviewer to offer' do
      reviewer = create(:user, :reviewer)
      offer = create :offer, :submitted
      expect{
        offer.assign_reviewer(reviewer)
      }.to change(offer, :reviewed_at)
      expect(offer.reviewed_by).to eq(reviewer)
    end
  end

  describe 'offer state change time attributes' do
    it 'should set submitted_at' do
      offer = create :offer, state: 'draft'
      expect{ offer.submit }.to change(offer, :submitted_at)
    end

    it 'should set reviewed_at' do
      offer = create :offer, :submitted
      expect{ offer.start_review }.to change(offer, :reviewed_at)
    end

    it 'should set review_completed_at' do
      offer = create :offer, :under_review
      expect{ offer.finish_review }.to change(offer, :review_completed_at)
    end

    it 'should set received_at' do
      offer = create :offer, :scheduled
      expect{ offer.receive }.to change(offer, :received_at)
    end
  end

end
