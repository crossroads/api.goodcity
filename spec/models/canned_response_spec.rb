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
      let!(:canned_response) { create(:canned_response, is_private: true) }

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
    end
  end

  describe '.by_private' do
    before do
      create_list(:canned_response, 5)
      create_list(:canned_response, 3, is_private: true)
    end

    it 'returns all private canned_responses for truthy argument' do
      result = CannedResponse.by_private(true)
      expect(result.pluck(:is_private).uniq).to match_array([true])
    end

    it 'returns all public canned_responses for falsy argument' do
      result = CannedResponse.by_private(false)
      expect(result.pluck(:is_private).uniq).to match_array([false])
    end
  end
end
