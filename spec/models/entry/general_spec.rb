# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../entry_spec_helper')

describe Entry::General do
  fixtures :accounts, :users, :account_links, :friend_permissions, :friend_requests
  set_fixture_class  :accounts => Account::Base
  include EntrySpecHelper

  describe "#valid?" do
    let(:entry) {new_general_entry(:taro_cache, 300)}
    it "正しい情報を与えたときにtrueとなる" do
      entry.should be_valid
    end

    it_behaves_like "valid? when including ::Entry"
  end

  describe "create" do
    let(:entry) {new_general_entry(:taro_cache, 300)}
    it_behaves_like "save when including ::Entry"
  end

  describe "update" do
    let(:entry) {e = new_general_entry(:taro_cache, 300); e.save!; e}
    it_behaves_like "save when including ::Entry"
  end
end