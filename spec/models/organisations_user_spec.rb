require "rails_helper"

RSpec.describe OrganisationsUser, type: :model do
  describe "Database columns" do
    it { is_expected.to have_db_column(:position).of_type(:string) }
    it { is_expected.to have_db_column(:user_id).of_type(:integer) }
    it { is_expected.to have_db_column(:organisation_id).of_type(:integer) }
    it { is_expected.to have_db_column(:preferred_contact_number).of_type(:string) }
  end

  describe "Associations" do
    it { is_expected.to belong_to :organisation }
    it { is_expected.to belong_to :user }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:organisation_id) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  describe '.validate_status' do
    context 'when status is valid' do
      it 'saves the record' do
        record = build(:organisations_user)
        expect { record.save }.to change { OrganisationsUser.count }.by(1)
      end

      it 'updates the record' do
        record = create(:organisations_user)
        record.update(status: 'denied')
        expect(record.reload.status).to eq('denied')
      end
    end

    context 'when status is invalid' do
      it 'throws error' do
        record = build(:organisations_user)
        record.status = 'ABC'
        expect {
          expect { record.save }.to raise_error(I18n.t("organisations_user_builder.invalid.status"))
        }.to_not change { OrganisationsUser.count }
      end
    end
  end

  describe '.downcase_status' do
    it 'downcase the status before save' do
      record = build(:organisations_user, status: 'Pending')
      record.save
      expect(record.reload.status).to eq('pending')
    end

    it 'downcase the status before update' do
      record = create(:organisations_user)
      record.update(status: 'Approved')
      expect(record.reload.status).to eq('approved')
    end
  end
end
