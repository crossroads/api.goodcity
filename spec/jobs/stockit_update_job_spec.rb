require "rails_helper"

describe StockitUpdateJob, :type => :job do

  let(:package) { create(:package, :stockit_package) }
  let(:err) { {"errors" => {:connection_error => "Error"}} }
  
  subject { StockitUpdateJob.new }

  it "should update the item in Stockit" do
    expect(Stockit::ItemSync).to receive(:update).with(package)
    subject.perform(package.id)
  end

  context "Stockit creates a new item" do
    let(:new_item_id) { package.stockit_id + 1 }
    let(:new_item_payload) { { "id" => new_item_id } }
    it "should update stockit_id" do
      expect(Stockit::ItemSync).to receive(:update).with(package).and_return(new_item_payload)
      expect(package).to receive(:update_attribute).with(stockit_id: new_item_id)
      subject.perform(package.id)
    end
    it "should not update stockit_id if it is blank" do
      expect(Stockit::ItemSync).to receive(:update).with(package).and_return( { id: nil } )
      expect(package).to_not receive(:update_attribute)
      subject.perform(package.id)
    end
  end

  it "should ignore packages that don't exist" do
    expect(Stockit::ItemSync).not_to receive(:update)
    subject.perform("1")
  end

  it "should log error messages" do
    expect(Stockit::ItemSync).to receive(:update).with(package).and_return(err)
    err_msg = "Inventory: #{package.inventory_number} Package: #{package.id} connection_error: Error"
    expect(subject).to receive_message_chain(:logger, :error).with(err_msg)
    subject.perform(package.id)
  end

end
