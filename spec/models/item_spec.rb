require 'rails_helper'

RSpec.describe Item, type: :model do

  describe 'Associations' do
    it { should belong_to :offer }
    it { should belong_to :item_type }
    it { should belong_to :rejection_reason }
    it { should have_many :messages }
    it { should have_many :images }
    it { should have_many :packages }
  end

  describe 'Database Columns' do
    it { should have_db_column(:donor_description).of_type(:text) }
    it { should have_db_column(:donor_condition).of_type(:string) }
    it { should have_db_column(:state).of_type(:string) }
    it { should have_db_column(:offer_id).of_type(:integer) }
    it { should have_db_column(:item_type_id).of_type(:integer) }
    it { should have_db_column(:rejection_reason_id).of_type(:integer) }
    it { should have_db_column(:rejection_other_reason).of_type(:string) }
    it { should have_db_column(:saleable).of_type(:boolean) }
  end

  describe 'Scope Methods' do
    let!(:offer) { create :offer }
    let!(:items) { create_list :item, 3, offer: offer }

    describe 'update_saleable' do
      it 'should update all items of offer' do
        expect{
          offer.items.update_saleable
        }.to change(Item.where(saleable: true), :count).by(3)
      end
    end
  end

end
