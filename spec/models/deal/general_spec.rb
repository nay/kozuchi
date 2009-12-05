require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Deal::General do
  fixtures :accounts, :account_links, :account_link_requests, :friend_requests, :friend_permissions, :users
  set_fixture_class  :accounts => Account::Base, :deals => Deal::Base

  before do
    @cache = accounts(:deal_test_cache)
    @bank = accounts(:deal_test_bank)
  end

#  describe "new" do
#
#    it "複数行のDealオブジェクトの作成に成功すること" do
#      deal = Deal::General.new(:summary => "複数行", :date => Date.new)
#    end
#
#  end


  describe "create" do

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
        deal.entries.build(
          :account_id => @cache.id,
          :amount => -10000)
        deal.entries.build(
          :account_id => @bank.id,
          :amount => 10000)
        deal.save.should be_true
        deal.entries.detect{|e| e.new_record?}.should be_nil
      end
    end

    describe "連携あり" do
      before do
        @taro = users(:taro)
        @hanako = users(:hanako)
        @home = users(:home)
        raise "@taroと@hanakoは友達" unless @taro.friend?(@hanako) && @hanako.friend?(@taro)
        raise "@taroと@homeは友達" unless @taro.friend?(@home) && @home.friend?(@taro)
        raise "@homeと@hanakoは友達" unless @home.friend?(@hanako) && @hanako.friend?(@home)
        @taro_cache = accounts(:taro_cache)
        @taro_hanako = accounts(:taro_hanako)
        @taro_home = accounts(:taro_home)
        @taro_home_cost = accounts(:taro_home_cost)

        @hanako_cache = accounts(:hanako_cache)
        @hanako_taro = accounts(:hanako_taro)
        @hanako_home = accounts(:hanako_home)
        @hanako_home_cost = accounts(:hanako_home_cost)

        @home_cache = accounts(:home_cache)
        @home_taro = accounts(:home_taro)
        @home_hanako = accounts(:home_hanako)
        @home_income_from_two = accounts(:home_income_from_two)

        raise "前提：@taro_hanakoは@hanako_taroと連携する" unless @taro_hanako.linked_account == @hanako_taro
        raise "前提：@hanako_taroは@taro_hanakoと連携する" unless @hanako_taro.linked_account == @taro_hanako

        raise "前提：@taro_homeは@home_taroと連携する" unless @taro_home.linked_account == @home_taro
        raise "前提：@home_taroは@taro_homeと連携する" unless @home_taro.linked_account == @taro_home

        raise "前提：@home_hanakoは@hanako_homeと連携する" unless @home_hanako.linked_account == @hanako_home
        raise "前提：@hanako_homeは@home_hanakoと連携する" unless @hanako_home.linked_account == @home_hanako

        raise "前提：@taro_home_costは@home_income_from_twoと連携する" unless @taro_home_cost.linked_account == @home_income_from_two
        raise "前提：@hanako_home_costは@home_income_from_twoと連携する" unless @hanako_home_cost.linked_account == @home_income_from_two
        raise "前提：@home_income_from_twoは連携記入先を持たない" unless @home_income_from_two.linked_account.nil?
      end

     describe "Dealに２つEntryがあり、片方のみが連携しているとき" do
       before do
         # taro_cache から taro_hanako へ 300円貸した
         @deal = Deal::General.new(:summary => "test", :date => Date.today)
         @deal.user_id = @taro.id
         @deal.entries.build(:account_id => @taro_cache.id, :amount => -300)
         @deal.entries.build(:account_id => @taro_hanako.id, :amount => 300)
         @deal.save!
         @linked_entry = @deal.entries.detect{|e| e.account_id == @taro_hanako.id}
         raise "前提：@linked_entryがセーブされている" if @linked_entry.new_record?
       end
       it "片方のEntryにリンクが作られること" do
         @linked_entry.linked_ex_entry_id.should_not be_nil
       end
       it "連携したDealの片方を消したら確認してない相手のdealも消される" do
         @hanako_deal = Deal::General.find(@linked_entry.linked_ex_deal_id)
         @deal.destroy
         Deal::General.find_by_id(@hanako_deal.id).should be_nil
       end
       it "連携したDealの片方を消したら確認している相手とのリンクが消される" do
         @hanako_deal = Deal::General.find(@linked_entry.linked_ex_deal_id)
         @hanako_deal.confirm
         @deal.destroy
         @hanako_deal.reload
         @hanako_unlinked_entry = @hanako_deal.entries.detect{|e| e.account_id == @hanako_taro.id}
         @hanako_unlinked_entry.reload
         @hanako_unlinked_entry.linked_ex_entry_id.should be_nil
       end
       it "連携があり確認済のときに金額を変更したら相手とのリンクが切られて新しく記入される" do
         @hanako_deal = Deal::General.find(@linked_entry.linked_ex_deal_id)
         @hanako_deal.confirm
#         @deal.entries.each{|e| e.amount *= 2}
#        効かない；；
         @deal.plus_account_id = @deal.plus_account_id
         @deal.minus_account_id = @deal.minus_account_id
         @deal.amount = @deal.amount * 2

#         p @deal.entries.map{|e| e.amount}
         @deal.save!
         @deal.reload
         p @deal.entries.map{|e| e.amount}
         new_entry = @deal.entries(true).detect{|e| e.account_id == @taro_hanako.id}
         new_entry.linked_ex_entry_id.should_not be_nil
         @linked_entry.reload
         @linked_entry.linked_ex_deal_id.should_not == @hanako_deal.id
         @hanako_deal.reload
         p @hanako_deal.entries(true).map{|e| e.linked_ex_entry_id}
       end
     end


    end

#
#    describe "両側連携" do
#      # TODO:
#    end
  end

  describe "update" do
    before do
      @deal = new_deal(6, 1, @cache, @bank, 3500)
      @deal.save!
    end
    it "dateを変更したらentriesのdateも変更される" do
      @deal.date = @deal.date - 7
      @deal.save!
      @deal.entries.detect{|e| e.user_id != @deal.user_id || e.date != @deal.date || e.daily_seq != @deal.daily_seq}.should be_nil
    end
  end

  def new_deal(month, day, from, to, amount, year = 2008)
    d = Deal::General.new(:summary => "#{month}/#{day}の買い物", :amount => amount, :minus_account_id => from.id, :plus_account_id => to.id, :date => Date.new(year, month, day))
    d.user_id = to.user_id
    d
  end

end
