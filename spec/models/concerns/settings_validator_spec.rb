require 'rails_helper'

context SettingsValidator do
  before do
    @user = create(:user, :reviewer)
    User.current_user = @user
  end

  it 'returns error if key setting is set to false' do
    storage_type = create(:storage_type, :with_box)
    package = build(:package, storage_type_id: storage_type.id)
    gc_setting1 = create(:goodcity_setting, key: "stock.enable_box_pallet_creation", value: "false")
    expect(package.valid?).to eq(false)
    expect(package.errors.full_messages).to eq(["Creation of box/pallet is not allowed."])
  end

  it 'doesnot add any error on the record' do
    storage_type = create(:storage_type, :with_box)
    package = build(:package, storage_type_id: storage_type.id)
    gc_setting = create(:goodcity_setting, key: "stock.enable_box_pallet_creation", value: "true")
    expect(package.valid?).to eq(true)
    expect(package.save).to eq(true)
  end
end
