# Entry を include しているクラスに共通の振る舞い

shared_examples "valid? when including ::Entry" do
  describe "amount" do
    it "0の場合は検証エラーとなる" do
      entry.amount = '0'
      expect(entry).not_to be_valid
    end

    it "'3a'の場合は検証エラーとなる" do
      entry.amount = '3a'
      expect(entry).not_to be_valid
    end

    it "'3.3'の場合は検証エラーとなる" do
      entry.amount = '3.3'
      expect(entry).not_to be_valid
    end

    it "未指定の場合は数値検証エラーとならない" do
      entry.amount = nil
      entry.valid?
      expect(entry.errors[:amount]).not_to be_include(I18n.t("errors.messages.not_a_number"))
    end
  end

end

shared_examples "save when including ::Entry" do
  it "account_id, amount, summary すべて未指定で検証をスキップして保存した場合に例外が発生する" do
    entry.amount = nil
    entry.account_id = nil
    entry.summary = nil
    expect { entry.save(:validate => false) }.to raise_error(RuntimeError)
  end
end