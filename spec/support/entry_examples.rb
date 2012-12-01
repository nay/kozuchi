# -*- encoding : utf-8 -*-

# Entry を include しているクラスに共通の振る舞い

shared_examples "including ::Entry" do
  describe "amount" do
    it "0の場合は検証エラーとなる" do
      entry.amount = '0'
      entry.should_not be_valid
    end

    it "'3a'の場合は検証エラーとなる" do
      entry.amount = '3a'
      entry.should_not be_valid
    end

    it "'3.3'の場合は検証エラーとなる" do
      entry.amount = '3.3'
      entry.should_not be_valid
    end
  end
end
