require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Deal::Balance do
  fixtures :users, :accounts
  set_fixture_class  :accounts => Account::Base

  describe "save" do

    describe "validate" do
      it "account_idなしでは検証エラー" do
        new_balance(:account_id => nil).save.should be_false
      end
      it "balanceなしでは検証エラー" do
        new_balance(:balance => nil).save.should be_false
      end
      it "dateなしでは検証エラー" do
        new_balance(:date => nil).save.should be_false
      end
    end
  end

  describe "create" do
    it "成功する" do
      new_balance.save.should be_true
    end

    describe "成功した場合" do
      before do
        @balance = new_balance
        @balance.save!
      end
      it "entryが作られる" do
        @balance.entry.should_not be_nil
        @balance.entry.should_not be_new_record
      end
      it "entryの日付とbalanceの日付が等しい" do
        @balance.entry.date.should == @balance.date
        @balance.entry.daily_seq.should == @balance.daily_seq
      end
      it "サマリーは空文字列" do
        @balance.summary.should == ""
      end
    end

    describe "コンマ付き文字列でbalanceを入れたとき" do
      before do
        @balance = new_balance(:balance => "30,333")
        @balance.save!
      end
      it "正規化されたentryが作られる" do
        @balance.entry.balance.should == 30333
      end
      it "balance.balanceも正規化されたものが返る" do
        @balance.balance.should == 30333
      end
    end

    describe "before create" do
      it "user_idなしでは例外" do
        lambda{new_balance(:user_id => nil).save!}.should raise_error(RuntimeError)
      end
    end
  end

  describe "update" do
    before do
      @balance = new_balance(:balance => 1000)
      @balance.save!
    end

    it "日付を変えたらentryも追随する" do
      @balance.date += 1
      @balance.save.should be_true
      @balance.reload
      @balance.entry.date.should == @balance.date
    end

    describe "initialだったBalanceをinitialじゃない位置に移動したとき" do
      before do
        raise "not initial balance" unless @balance.entry.initial_balance?
        raise "balance is not 1000" unless @balance.entry.balance == 1000
        raise "amount is not 1000" unless @balance.entry.amount == 1000

        @balance2 = new_balance(:date => @balance.date + 2, :balance => 1333)
        @balance2.save!
        # 前提：amount は333 になっているはず
        raise "amount is not 333" unless @balance2.entry.amount == 333

        # この時点で以下のようになっていることを想定する
        #           記入   amount
        # balance   1000   1000 (initial)
        # balance2  1333   333

        # balanceをbalance2の後に移動する
        @balance.date = @balance2.date + 1
        @balance.save!
        @balance.reload
        @balance2.reload
      end
      it "amountが正しく変更される" do
        # 以下のようになることを想定する
        #           記入   amount
        # balance2  1333   1333    (initial)
        # balance   1000   -333
        @balance2.entry.amount.should == 1333
        @balance.entry.amount.should == -333
        @balance2.entry.initial_balance?.should be_true
        @balance.entry.initial_balance?.should be_false
      end
    end

  end

  def new_balance(attributes={})
    Deal::Balance.new({:date => Date.today, :user_id => Fixtures.identify(:taro), :account_id => Fixtures.identify(:taro_cache), :balance => 1000}.merge(attributes))
  end
end
