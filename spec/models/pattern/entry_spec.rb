require 'spec_helper'

describe Pattern::Entry do
  fixtures :accounts, :users, :account_links, :friend_permissions, :friend_requests

  describe ".new" do
    it do
      expect{Pattern::Entry.new}.not_to raise_error
    end
  end

  describe "#valid?" do
    let(:entry) {build(:entry_pattern)}

    it "正しい情報を与えたときにtrueとなる" do
      expect(entry).to be_valid
    end

    it_behaves_like "valid? when including ::Entry"
  end

  describe "create" do
    let(:entry) {build(:entry_pattern)}
    it_behaves_like "save when including ::Entry"
  end

  describe "update" do
    let(:entry) {build(:entry_pattern)}
    it_behaves_like "save when including ::Entry"
  end

end
