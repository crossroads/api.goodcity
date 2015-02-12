shared_examples 'name_with_language' do

  describe "#current_language" do
    it "returns name_zh_tw for chinese" do
      I18n.locale = 'zh-tw'
      expect(described_class.new("test").name__sql).to eq("name_zh_tw")
    end

    it "returns name_en for english" do
      I18n.locale = 'en'
      expect(described_class.new("test").name__sql).to eq("name_en")
    end
  end
end
