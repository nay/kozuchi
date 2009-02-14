require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AccountEntry do
  fixtures :accounts, :users
  set_fixture_class  :accounts => Account::Base

  before do
    @cache = accounts(:account_enrty_test_cache)
    @food = accounts(:account_entry_test_food)
  end

  describe "attributes=" do
    it "user_idは一括指定できない" do
      AccountEntry.new(:user_id => 3).user_id.should be_nil
    end
    it "deal_idは一括指定できない" do
      AccountEntry.new(:deal_id => 7).deal_id.should be_nil
    end
    it "account_idは一括指定できる" do
      AccountEntry.new(:account_id => 5).account_id.should == 5
    end
    it "friend_link_idは一括指定できない" do
      AccountEntry.new(:friend_link_id => 13).friend_link_id.should be_nil
    end
    it "dateは一括指定できない" do
      AccountEntry.new(:date => Date.today).date.should be_nil
    end
    it "daily_seqは一括指定できない" do
      AccountEntry.new(:daily_seq => 3).daily_seq.should be_nil
    end
    it "settlement_idは一括指定できない" do
      AccountEntry.new(:settlement_id => 10).settlement_id.should be_nil
    end
    it "result_settlement_idは一括指定できない" do
      AccountEntry.new(:result_settlement_id => 10).result_settlement_id.should be_nil
    end

  end

  describe "validate" do
    it "amountが指定されていないと検証エラー" do
      new_account_entry(:amount => nil).valid?.should be_false
    end
    it "account_idが指定されていないと検証エラー" do
      new_account_entry(:account_id => nil).valid?.should be_false
    end
  end

  describe "create" do
    it "account_id, amount, date, daily_seq があれば、user_id, deal_id の値によらず成功する" do
      e = AccountEntry.new(:amount => 400, :account_id => @cache.id)
      e.date = Date.today
      e.daily_seq = 1
      e.save.should be_true
    end
  end


  describe "destroy" do
    it "精算が紐付いていなければ消せる" do
      e = new_account_entry
      e.save!
      lambda{e.destroy}.should_not raise_error
    end
  end

  describe "settlement_attached?" do
    before do
      @entry = new_account_entry
    end
    it "settlement_id も result_settlement_idもないとき falseとなる" do
      @entry.save!
      @entry.settlement_attached?.should be_false
    end
    it "settlement_id があれば true になる" do
      @entry.settlement_id = 130 # 適当
      @entry.save!
      @entry.settlement_attached?.should be_true
    end
    it "result_settlement_id があれば true になる" do
      @entry.result_settlement_id = 130 # 適当
      @entry.save!
      @entry.settlement_attached?.should be_true
    end
  end

  describe "mate_account_name" do
    it "紐付いたdealがなければAssociatedObjectMissingErrorが発生する" do
      @entry = new_account_entry
      @entry.save!
      lambda{@entry.mate_account_name}.should raise_error(AssociatedObjectMissingError)
    end

    it "相手勘定が１つなら、相手勘定の名前が返される" do
      deal = new_deal(3, 3, @cache, @food, 180)
      deal.save!
#        deal = Deal.new(:summary => "買い物", :date => Date.today)
#        deal.account_entries.build(:amount => 180, :account_id => @food.id)
#        deal.account_entries.build(:amount => -180, :account_id => @cache.id)
#        deal.save!
      cache_entry = deal.account_entries.detect{|e| e.account_id == @cache.id}
      cache_entry.mate_account_name.should == @food.name
    end
  end

  # ----- Utilities -----
  def new_account_entry(attributes = {}, manual_attributes = {})
      e = AccountEntry.new({:amount => 2980, :account_id => @cache.id}.merge(attributes))
      manual_attributes = {:date => Date.today, :daily_seq => 1}.merge(manual_attributes)
      manual_attributes.keys.each do |key|
        e.send("#{key}=", manual_attributes[key])
      end
      e
  end
  
  # TODO: dealの作り方をなおすまでとりあえず
  def new_deal(month, day, from, to, amount, year = 2008)
    d = Deal.new(:summary => "#{month}/#{day}の買い物", :amount => amount, :minus_account_id => from.id, :plus_account_id => to.id, :date => Date.new(year, month, day))
    d.user_id = to.user_id
    d
  end

end
