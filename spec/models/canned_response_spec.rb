# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CannedResponse, type: :model do
  describe 'Database Columns' do
    it { is_expected.to have_db_column(:name_en).of_type(:string) }
    it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
    it { is_expected.to have_db_column(:content_en).of_type(:string) }
    it { is_expected.to have_db_column(:content_zh_tw).of_type(:string) }
    it { is_expected.to have_db_column(:respondable_type).of_type(:string) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name_en) }
    it { is_expected.to validate_presence_of(:content_en) }
    it { is_expected.to validate_uniqueness_of(:guid) }

    context 'when is_private is true' do
      let!(:canned_response) { create(:canned_response, :system) }

      context 'on deleting' do
        it 'does not allow to delete the message' do
          expect {
            canned_response.destroy
          }.not_to change { CannedResponse.count }
        end
      end

      it 'is able to edit the content' do
        expect {
          canned_response.update(content_en: 'Changed')
        }.to change { canned_response.content_en }
      end

      it 'allows to create guid with nil values' do
        expect {
          create_list(:canned_response, 2, guid: nil)
        }.to change { CannedResponse.count }.by(2)
      end
    end
  end

  describe '.by_type' do
    before do
      create_list(:canned_response, 5)
      create_list(:canned_response, 3, :system)
    end

    it 'returns all private canned_responses for truthy argument' do
      result = CannedResponse.by_type(CannedResponse::Type::SYSTEM)
      expect(result.pluck(:message_type).uniq).to match_array([CannedResponse::Type::SYSTEM])
      expect(result.length).to eq(3)
    end

    it 'returns all public canned_responses for falsy argument' do
      result = CannedResponse.by_type(CannedResponse::Type::USER)
      expect(result.pluck(:message_type).uniq).to match_array([CannedResponse::Type::USER])
      expect(result.length).to eq(5)
    end
  end

  describe '#system_message?' do
    let(:system_message) { create(:canned_response, :system) }
    let(:user_message) { create(:canned_response) }

    it 'returns true for system_message' do
      expect(system_message.system_message?).to be_truthy
    end

    it 'returns false for user_message' do
      expect(user_message.system_message?).to be_falsy
    end
  end

  describe '#user_message?' do
    let(:system_message) { create(:canned_response, :system) }
    let(:user_message) { create(:canned_response) }

    it 'returns true for user_message' do
      expect(user_message.user_message?).to be_truthy
    end

    it 'returns false for system_message' do
      expect(system_message.user_message?).to be_falsy
    end
  end
end
