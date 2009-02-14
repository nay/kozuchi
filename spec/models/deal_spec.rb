require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Deal do
  fixtures :accounts, :users
  set_fixture_class  :accounts => Account::Base

  before do
    @cache = accounts(:deal_test_cache)
    @bank = accounts(:deal_test_bank)
  end

  describe "create" do
    before do
      @deal = new_deal(6, 1, @cache, @bank, 3500)
    end

    it "成功する" do
      @deal.save.should be_true
    end

    it "user_id, date, daily_seqがentriesに引き継がれる" do
      @deal.save!
      @deal.account_entries.detect{|e| e.user_id != @deal.user_id || e.date != @deal.date || e.daily_seq != @deal.daily_seq}.should be_nil
    end
  end

  describe "update" do
    before do
      @deal = new_deal(6, 1, @cache, @bank, 3500)
      @deal.save!
    end
    it "dateを変更したらentriesのdateも変更される" do
      @deal.date = @deal.date - 7
      @deal.save!
      @deal.account_entries.detect{|e| e.user_id != @deal.user_id || e.date != @deal.date || e.daily_seq != @deal.daily_seq}.should be_nil
    end
  end

  def new_deal(month, day, from, to, amount, year = 2008)
    d = Deal.new(:summary => "#{month}/#{day}の買い物", :amount => amount, :minus_account_id => from.id, :plus_account_id => to.id, :date => Date.new(year, month, day))
    d.user_id = to.user_id
    d
  end

end
