shared_examples 'name_with_language' do

  describe "#current_language" do
    it "returns name_zh_tw for chinese" do
      in_locale 'zh-tw' do
        expect(described_class.new("test").name__sql).to eq("name_zh_tw")
      end
    end

    it "returns name_en for english" do
      in_locale 'en' do
        expect(described_class.new("test").name__sql).to eq("name_en")
      end
    end
  end
end
