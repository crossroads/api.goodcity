require 'rails_helper'

context SubformCallbacks do
  before do
    @user = create(:user, :reviewer)
    User.current_user = @user
  end

  it "calls downcase brand callback" do
    computer  = build(:computer, brand: "ApPLe")
    computer.run_callbacks :save
    expect(computer.brand).to eq("apple")
    expect(computer.updated_by_id).to eq(@user.id)
  end

  it "calls tested on callback" do
    electrical  = build(:electrical, brand: "PhiliPs", test_status: "")
    electrical.run_callbacks :save
    expect(electrical.brand).to eq("philips")
    expect(electrical.updated_by_id).to eq(@user.id)
    expect(electrical.tested_on).to eq(Date.today())
  end

  it "calls create callback" do
    computer  = build(:computer)
    expect(Stockit::ItemDetailSync).to receive(:create).with(computer).and_return({"status"=>201, "computer_id"=> 12})
    computer.save
  end

  it "calls create callback" do
    computer  = build(:computer)
    expect(Stockit::ItemDetailSync).to receive(:create).with(computer).and_return({"status"=>201, "computer_id"=> 12})
    computer.save
    expect(Stockit::ItemDetailSync).to receive(:update).with(computer).and_return({"status"=>201, "computer_id"=> 12})
    computer.update(brand: "lenovo")
    expect(computer.brand).to eq("lenovo")
  end
end
