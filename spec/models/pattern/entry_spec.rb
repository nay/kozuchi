# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Pattern::Entry do
  fixtures :accounts, :users, :account_links, :friend_permissions, :friend_requests
  set_fixture_class  :accounts => Account::Base

  describe ".new" do
    it do
      expect{Pattern::Entry.new}.not_to raise_error
    end
  end

  describe "#valid?" do
    let(:entry) {FactoryGirl.build(:entry_pattern)}

    it "正しい情報を与えたときにtrueとなる" do
      entry.should be_valid
    end

    it_behaves_like "including ::Entry"
  end
end
