shared_examples 'paranoid' do
  describe "#recover" do
    let!(:record) { create ("paranoid_#{described_class.to_s.downcase}").to_sym }

    it "recovery of records" do
      record.destroy

      record.recover
      record.reload
      expect(record.destroyed?).to be false

      record.class.reflect_on_all_associations(:has_many).map do |assoc|
        record.send(assoc.name).each do |store|
          expect(store.destroyed?).to be false
        end
      end
    end
  end
end
