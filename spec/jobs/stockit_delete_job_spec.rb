require "rails_helper"

describe StockitDeleteJob, :type => :job do

  let(:inventory_number) { "H12345" }
  let(:err) { {"errors" => {:connection_error => "Error"}} }

  subject { StockitDeleteJob.new }

  it "should delete the item in Stockit" do
    expect(Stockit::ItemSync).to receive(:delete).with(inventory_number)
    subject.perform(inventory_number)
  end

  it "should log error messages" do
    expect(Stockit::ItemSync).to receive(:delete).with(inventory_number).and_return(err)
    err_msg = "Inventory number: #{inventory_number} connection_error: Error"
    expect(subject).to receive_message_chain(:logger, :error).with(err_msg)
    subject.perform(inventory_number)
  end

end
