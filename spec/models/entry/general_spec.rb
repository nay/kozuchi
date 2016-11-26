# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../entry_spec_helper')

describe Entry::General do
  fixtures :accounts, :users, :account_links, :friend_permissions, :friend_requests
  include EntrySpecHelper

  describe "#amount=" do
    context "コンマ入りの数値が代入されたとき" do
      let(:entry) { FactoryGirl.build(:general_entry, :amount => '10,000') }
      it {entry.amount.should == 10000 }
    end
  end

  describe "#reversed_amount=" do
    context "コンマ入りの数値が代入されたとき" do
      let(:entry) { FactoryGirl.build(:general_entry, :amount => nil) }
      before do
        entry.reversed_amount = '10,000'
      end
      it "コンマを織り込んで符号が逆になった値がamountに入ること" do
        entry.amount.should == -10000
      end
      it "reversed_amount_before_type_castは'10000'になる" do
        entry.reversed_amount_before_type_cast.should == '10000'
      end
      it "reversed_amountは10000になる" do
      end
      it "金額が検証エラーにならないこと" do
        entry.valid?
        entry.errors[:amount].should be_empty
      end
    end
    context "生の数値が代入されたとき" do
      let(:entry) { FactoryGirl.build(:general_entry, :amount => nil) }
      before do
        entry.reversed_amount = 3800
      end
      it "符号が逆になった値がamountに入ること" do
        entry.amount.should == -3800
      end
      it "reversed_amount_before_type_castは3800になる" do
        entry.reversed_amount_before_type_cast.should == 3800
      end
      it "金額が検証エラーにならないこと" do
        entry.valid?
        entry.errors[:amount].should be_empty
      end
    end
    context "数値でない文字列が代入されたとき" do
      let(:entry) { FactoryGirl.build(:general_entry, :amount => nil) }
      before do
        entry.reversed_amount = 'aaa'
      end
      it "amountは0になる" do
        entry.amount.should == 0
      end
      it "reversed_amount_before_type_castは'aaa'になる" do
        entry.reversed_amount_before_type_cast.should == 'aaa'
      end
      it "金額が検証エラーになる" do
        entry.valid?
        entry.errors[:amount].should_not be_empty
      end
    end
    context "少数点付きの文字列が代入されたとき" do
      let(:entry) { FactoryGirl.build(:general_entry, :amount => nil) }
      before do
        entry.reversed_amount = '1.10'
      end
      it "amountは1になる" do
        entry.amount.should == 1
      end
      it "reversed_amount_before_type_castは'1.10'になる" do
        entry.reversed_amount_before_type_cast.should == '1.10'
      end
      it "金額が検証エラーになる" do
        entry.valid?
        entry.errors[:amount].should_not be_empty
      end
    end
  end

  describe "#valid?" do
    let(:entry) { new_general_entry(:taro_cache, 300)}
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