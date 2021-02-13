require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../../entry_spec_helper')

describe Entry::Balance do
  fixtures :accounts, :users
  include EntrySpecHelper

  describe "#balance=" do
    context "'900'をいれたとき" do
      let(:entry) { build(:balance_entry, :balance => '900') }
      it "balanceは900" do
        expect(entry.balance).to eq 900
      end
    end
    context "'1,980'をいれたとき" do
      let(:entry) { build(:balance_entry, :balance => '1,980') }
      it "balanceは1980" do
        expect(entry.balance).to eq 1980
      end
    end
    context "'foo'をいれたとき" do
      let(:entry) { build(:balance_entry, :balance => 'foo') }
      it "balanceは0" do
        expect(entry.balance).to eq 0
      end
      it "検証エラーとなる" do
        entry.valid?
        expect(entry.errors[:balance]).not_to be_empty
      end
    end
  end
end