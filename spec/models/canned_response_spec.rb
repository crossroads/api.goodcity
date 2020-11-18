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
  end
end
