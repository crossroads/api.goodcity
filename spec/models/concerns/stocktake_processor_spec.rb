require 'rails_helper'

context StocktakeProcessor do
  let(:location) { create(:location) }
  let(:stocktake) { create(:stocktake, location: location) }
  let(:package_1) { create(:package, received_quantity: 10) }
  let(:package_2) { create(:package, received_quantity: 10) }
  let(:package_3) { create(:package, received_quantity: 10) }

  let(:subject) {
    Class.new { include StocktakeProcessor }
  }

  before { initialize_inventory(package_1, package_2, package_3, location: location) }
  
  describe 'Processing a stocktake' do
    before do
      create(:stocktake_revision, package: package_1, stocktake: stocktake, quantity: 12)  # we counted more 
      create(:stocktake_revision, package: package_2, stocktake: stocktake, quantity: 8)   # we counted less
      create(:stocktake_revision, package: package_3, stocktake: stocktake, quantity: 10)  # we counted the same amount
    end

    it 'creates packages_inventory rows for each difference found' do
      expect { 
        subject.process_stocktake(stocktake);
      }.to change(PackagesInventory, :count).by(2)

      changed_ids = PackagesInventory.last(2).map { |p| p.package_id }
      expect(changed_ids).to match_array([package_1.id, package_2.id])
    end

    it 'records a gain to account for positive differences' do
      errors = subject.process_stocktake(stocktake);

      expect(errors.length).to eq(0)
      packages_inventory = PackagesInventory.last(2).select { |pi| pi.package_id == package_1.id }.first

      expect(packages_inventory.action).to eq('gain')
      expect(packages_inventory.quantity).to eq(2)
      expect(packages_inventory.source_id).to eq(stocktake.id)
      expect(packages_inventory.description).to eq(stocktake.name)
    end

    it 'records a loss to account for negative differences' do
      errors = subject.process_stocktake(stocktake);

      expect(errors.length).to eq(0)
      packages_inventory = PackagesInventory.last(2).select { |pi| pi.package_id == package_2.id }.first

      expect(packages_inventory.action).to eq('loss')
      expect(packages_inventory.quantity).to eq(-2)
      expect(packages_inventory.source_id).to eq(stocktake.id)
      expect(packages_inventory.description).to eq(stocktake.name)
    end

    it 'doesnt record anything it the quantity is already correct' do
      errors = subject.process_stocktake(stocktake);
      
      expect(errors.length).to eq(0)
      expect(
        PackagesInventory
          .where(package: package_3)
          .where.not(action: 'inventory')
          .count
      ).to eq(0)
    end

    it 'closes the stocktake' do
      expect {
        subject.process_stocktake(stocktake)
      }.to change {
        stocktake.reload.state
      }.from('open').to('closed')
    end

    it 'marks all the revisions as processed' do
      expect {
        subject.process_stocktake(stocktake)
      }.to change {
        stocktake.reload.revisions.pluck(:state).uniq
      }.from(['pending']).to(['processed'])
    end
    
    it 'fails to process an already processed stocktake' do
      expect { subject.process_stocktake(stocktake); }.to change(PackagesInventory, :count).by(2)
      expect { subject.process_stocktake(stocktake); }.to raise_error(Goodcity::InvalidStateError).with_message('Cannot process a closed or cancelled Stocktake')
    end

    it 'fails to process a stocktake with revisions marked as dirty' do
      StocktakeRevision.last.update(dirty: true)
      expect { subject.process_stocktake(stocktake); }.to raise_error(Goodcity::InvalidStateError).with_message('Some quantity revisions require a re-count')
    end

    describe 'when an error occurs' do
      before do
        # This quantity designated, therefore cannot be reduced in the inventory
        create(:orders_package, package: package_2, quantity: 10)
      end

      it 'doesnt record any inventory change' do
        expect {
          errors = subject.process_stocktake(stocktake);
          expect(errors.length).to eq(1)
          expect(errors.first).to match(/please undesignate first/)
        }.not_to change(PackagesInventory, :count)
      end

      it 'adds a warning to the revision record' do
        stocktake_revision = StocktakeRevision.find_by(package: package_2);
        expect(stocktake_revision.reload.warning_en).to eq('');
        subject.process_stocktake(stocktake);
        expect(stocktake_revision.reload.warning_en).to match(/please undesignate first/);
      end
    end
  end
end
