require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Deal::General do
  fixtures :accounts, :account_links, :account_link_requests, :friend_requests, :friend_permissions, :users
  set_fixture_class  :accounts => Account::Base, :deals => Deal::Base

  before do
    @cache = accounts(:deal_test_cache)
    @bank = accounts(:deal_test_bank)
  end

  describe "new" do
    it "複数行のDealオブジェクトの作成に成功すること" do

      # 食費 1300   現金 1000
      #            銀行  300
      deal = Deal::General.new(:summary => "複数行", :date => Date.new,
        :debtor_entries_attributes => [{
            :account_id => Fixtures.identify(:taro_food),
            :amount => 1300
          }],
        :creditor_entries_attributes => [{
            :account_id => Fixtures.identify(:taro_cache),
            :amount => -1000
          },
          {
            :account_id => Fixtures.identify(:taro_bank),
            :amount => -300
          }
        ]
      )
      deal.debtor_entries.size.should == 1
      deal.creditor_entries.size.should == 2
    end
  end

  describe "valid?" do
    it "数字の合った複合Dealが検証をとおること" do
      deal = new_complex_deal(3, 1, {:taro_food => 1300},{:taro_cache => -1000, :taro_bank => -300})
      deal.valid?.should be_true
    end
    it "数字の合わない複合Dealが検証を通らないこと" do
      deal = new_complex_deal(3, 1, {:taro_food => 1300},{:taro_cache => -1000, :taro_bank => -200})
      deal.valid?.should be_false
    end
    it "amountが0のEntryを含む複合Dealが検証を通らないこと" do
      deal = new_complex_deal(3, 1, {:taro_food => 1300},{:taro_cache => -1300, :taro_bank => 0})
      deal.valid?.should be_false
    end
    # この制約は不具合を出にくくするために入れている
    # 暫定措置
    it "複合Dealの各Entryの口座に重複がないこと" do
      deal = new_complex_deal(3, 1, {:taro_food => 1400}, {:taro_cache => -1300, :taro_food => -100})
      deal.valid?.should be_false
    end

    it "同じ口座間での移動が検証を通らないこと" do
      deal = new_deal(3, 1, :taro_food, :taro_food, 300)
      deal.valid?.should be_false
    end
    it "金額が0ではいけないこと" do
      deal = new_deal(3, 1, :taro_food, :taro_cache, 0)
      deal.valid?
      deal.valid?.should be_false
    end
  end

  describe "create" do

    it "数字の合った複合Dealが作成できること" do
      deal = new_complex_deal(3, 1, {:taro_food => 1300},{:taro_cache => -1000, :taro_bank => -300})
      deal.save.should be_true
    end
    it "カンマ入り数字による複合Dealが作成できること" do
      deal = new_complex_deal(3, 1, {:taro_food => '1,300'},{:taro_cache => '-1,000', :taro_bank => '-300'})
      deal.save.should be_true
      deal.debtor_entries.any?{|e| e.amount.to_i == 1300}.should be_true
    end

    describe "連携なし" do
      before do
        @deal = new_deal(6, 1, @cache, @bank, 3500)
      end

      it "成功する" do
        @deal.save.should be_true
      end

      it "user_id, date, daily_seqがentriesに引き継がれる" do
        @deal.save!
        @deal.entries.detect{|e| e.user_id != @deal.user_id || e.date != @deal.date || e.daily_seq != @deal.daily_seq}.should be_nil
      end

      it "account_entryを手動で足してもcreateできる" do
        user = users(:deal_test_user)
        deal = Deal::General.new(:summary => "test", :date => Date.today)
        deal.user_id = user.id
        deal.creditor_entries.build(
          :account_id => @cache.id,
          :amount => -10000)
        deal.debtor_entries.build(
          :account_id => @bank.id,
          :amount => 10000)
        deal.save.should be_true
        deal.creditor_entries.detect{|e| e.new_record?}.should be_nil
        deal.debtor_entries.detect{|e| e.new_record?}.should be_nil
      end
    end

  end

  describe "update" do
    before do
      @deal = new_deal(6, 1, @cache, @bank, 3500)
      @deal.save!
      @deal.reload
    end
    # 複数記入への変更
    it "貸し方の項目を足して複数記入に変更できる" do
      @deal.attributes = {
        :creditor_entries_attributes => {
          '0' => {:account_id => @cache.id, :amount => -3200, :id => @deal.creditor_entries(true).first.id},
          '1' => {:account_id => :deal_test_food.to_id, :amount => -300}
        },
        :debtor_entries_attributes => {
          '0' => {:account_id => @bank.id, :amount => 3500, :id => @deal.debtor_entries(true).first.id}
        }
      }
      @deal.creditor_entries.size.should == 3 # 一時的に３つになる
      @deal.creditor_entries.first.marked_for_destruction?.should be_true
      @deal.creditor_entries[1].amount.should == -3200
      @deal.creditor_entries[2].amount.should == -300
      @deal.valid?.should be_true
      @deal.save.should be_true
      @deal.reload
      @deal.creditor_entries.size.should == 2
      @deal.debtor_entries.size.should == 1
    end
    it "借り方の項目を足して複数記入に変更できる" do
      @deal.attributes = {
        :creditor_entries_attributes => {
          '0' => {:account_id => @cache.id, :amount => -3500, :id => @deal.creditor_entries(true).first.id}
        },
        :debtor_entries_attributes => {
          '0' => {:account_id => @bank.id, :amount => 3200, :id => @deal.debtor_entries(true).first.id},
          '1' => {:account_id => :deal_test_food.to_id, :amount => 300}
        }
      }
      @deal.debtor_entries.size.should == 3 # 一時的に３つになる
      @deal.debtor_entries.first.marked_for_destruction?.should be_true
      @deal.debtor_entries[1].amount.should == 3200
      @deal.debtor_entries[2].amount.should == 300
      @deal.valid?.should be_true
      @deal.save.should be_true
      @deal.reload
      @deal.creditor_entries.size.should == 1
      @deal.debtor_entries.size.should == 2
      
    end
    it "dateを変更したらentriesのdateも変更される" do
      @deal.date = @deal.date - 7
      @deal.save!
      @deal.entries.detect{|e| e.user_id != @deal.user_id || e.date != @deal.date || e.daily_seq != @deal.daily_seq}.should be_nil
    end
    it "NestedAttributesを使って変更なしでsave!されたとき、entryが変化しない" do
      old_debtor_entry = @deal.debtor_entries.first
      old_creditor_entry = @deal.creditor_entries.first
      @deal.attributes = {
        :debtor_entries_attributes => {'0' => {:account_id => @bank.id, :amount => 3500, :id => old_debtor_entry.id}},
        :creditor_entries_attributes => {'0' => {:account_id => @cache.id, :amount => -3500, :id => old_creditor_entry.id}}
      }
      @deal.save!

      @deal.reload
      @deal.debtor_entries.size.should == 1
      new_debtor_entry = @deal.debtor_entries.first
      new_debtor_entry.id.should == old_debtor_entry.id
      new_debtor_entry.amount.should == old_debtor_entry.amount
      new_debtor_entry.account_id.should == old_debtor_entry.account_id
      new_debtor_entry.user_id.should == old_debtor_entry.user_id

      @deal.creditor_entries.size.should == 1
      new_creditor_entry = @deal.creditor_entries.first
      new_creditor_entry.id.should == old_creditor_entry.id
      new_creditor_entry.amount.should == old_creditor_entry.amount
      new_creditor_entry.account_id.should == old_creditor_entry.account_id
      new_creditor_entry.user_id.should == old_creditor_entry.user_id
    end
  
  end

  def to_account_id(value)
    case value
    when Symbol
      Fixtures.identify(value)
    when ActiveRecord::Base
      value.id
    else
      value
    end
  end

  def new_deal(month, day, from, to, amount, year = 2008)
    d = Deal::General.new(:summary => "#{month}/#{day}の買い物",
      :debtor_entries_attributes => [:account_id => to_account_id(to), :amount => amount],
      :creditor_entries_attributes => [:account_id => to_account_id(from), :amount => amount * -1],
      #      :amount => amount, :minus_account_id => from.id, :plus_account_id => to.id,
      :date => Date.new(year, month, day))
    to_account = Account::Base.find(to_account_id(to))
    d.user_id = to_account.user_id
    d
  end

  # debtors {account_id => amout, account_id => amount} のように記述
  def new_complex_deal(month, day, debtors, creditors, options = {})
    summary = options[:summary] || "#{month}/#{day}の記入"
    date = Date.new(options[:year] || 2010, month, day)

    deal = Deal::General.new(:summary => summary, :date => date,
      :debtor_entries_attributes => debtors.map{|key, value| {:account_id => (key.kind_of?(Symbol) ? Fixtures.identify(key) : key), :amount => value} },
      :creditor_entries_attributes => creditors.map{|key, value| {:account_id => (key.kind_of?(Symbol) ? Fixtures.identify(key) : key), :amount => value}}
    )
    
    key = debtors.keys.first
    account_id = key.kind_of?(Symbol) ? Fixtures.identify(key) : key
    account = Account::Base.find_by_id(account_id)
    raise "no account" unless account
    deal.user_id = account.user_id
    deal
  end

end
