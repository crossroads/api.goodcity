require "rails_helper"

describe StocktakeJob, :type => :job do
  let(:location) { create(:location) }
  let(:stocktake) { create(:stocktake, location: location) }
  let(:package_1) { create(:package, received_quantity: 10) }
  let(:package_2) { create(:package, received_quantity: 10) }
  let(:package_3) { create(:package, received_quantity: 10) }

  before do
    touch(stocktake)
    initialize_inventory(package_1, package_2, package_3, location: location)
    create(:stocktake_revision, package: package_1, stocktake: stocktake, quantity: 12)  # we counted more
    create(:stocktake_revision, package: package_2, stocktake: stocktake, quantity: 8)   # we counted less
    create(:stocktake_revision, package: package_3, stocktake: stocktake, quantity: 10)  # we counted the same amount
  end

  [
    'closed',
    'cancelled',
    'open',
    'processing'
  ].each do |state|
    it "does not calls the stocktake processor if the state is #{state}" do
      stocktake.update(state: state)
      expect(Stocktake).not_to receive(:process_stocktake)
      StocktakeJob.new.perform(stocktake.id)
    end
  end

  context 'for a stocktake awaiting processing' do
    before do
      stocktake.update(state: 'awaiting_process')
    end

    it "calls the stocktake processor" do
      expect(Stocktake).to receive(:process_stocktake).once.with(stocktake).and_call_original
      StocktakeJob.new.perform(stocktake.id)
    end

    it "creates inventory rows to correct the quantities" do
      expect(Stocktake).to receive(:process_stocktake).once.with(stocktake).and_call_original

      expect {
        StocktakeJob.new.perform(stocktake.id)
      }.to change(PackagesInventory, :count).by(2)

      change_1, change_2 = PackagesInventory.last(2)
      expect(change_1.package_id).to eq(package_1.id)
      expect(change_1.quantity).to eq(2)
      expect(change_2.package_id).to eq(package_2.id)
      expect(change_2.quantity).to eq(-2)
    end

    it "closes the stocktake" do
      expect {
        StocktakeJob.new.perform(stocktake.id)
      }.to change { stocktake.reload.state }.from('awaiting_process').to('closed')
    end

    it "reopens the stocktake if any error occurs" do
      # Designating the package prevents its quantity from being lowered in the stocktake process
      create(:orders_package, state: 'designated', package: package_2, quantity: 10)

      expect {
        StocktakeJob.new.perform(stocktake.id)
      }.to change { stocktake.reload.state }.from('awaiting_process').to('open')
    end
  end
end
