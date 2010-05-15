# 連携機能に特化したスペック

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Deal Linking" do
  fixtures :accounts, :account_links, :account_link_requests, :friend_requests, :friend_permissions, :users
  set_fixture_class  :accounts => Account::Base, :deals => Deal::Base

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

    raise "前提：@taro_hanakoは@hanako_taroと連携する" unless @taro_hanako.destination_account == @hanako_taro
    raise "前提：@hanako_taroは@taro_hanakoと連携する" unless @hanako_taro.destination_account == @taro_hanako

    raise "前提：@taro_homeは@home_taroと連携する" unless @taro_home.destination_account == @home_taro
    raise "前提：@home_taroは@taro_homeと連携する" unless @home_taro.destination_account == @taro_home

    raise "前提：@home_hanakoは@hanako_homeと連携する" unless @home_hanako.destination_account == @hanako_home
    raise "前提：@hanako_homeは@home_hanakoと連携する" unless @hanako_home.destination_account == @home_hanako

    raise "前提：@taro_home_costは@home_income_from_twoと連携する" unless @taro_home_cost.destination_account == @home_income_from_two
    raise "前提：@hanako_home_costは@home_income_from_twoと連携する" unless @hanako_home_cost.destination_account == @home_income_from_two
    raise "前提：@home_income_from_twoは連携記入先を持たない" unless @home_income_from_two.destination_account.nil?
  end

  describe "create" do

    it "シンプルな片面連携取引が作成できること" do
      prepare_simple_taro_deal_with_one_link
      # セーブが成功する
      lambda{@taro_deal.save!}.should_not raise_error
      # 太郎側の記入に連携情報が入る
      taro_linked_entry = @taro_deal.debtor_entries.first
      taro_linked_entry.linked_ex_deal_id.should_not be_nil
      taro_linked_entry.linked_ex_entry_id.should_not be_nil
      taro_linked_entry.linked_ex_entry_confirmed.should be_false
      taro_linked_entry.linked_user_id.should == @hanako.id
      # 太郎側の相手記入には連携情報が入らない
      taro_partner_entry = @taro_deal.creditor_entries.first
      taro_partner_entry.linked_ex_entry_id.should be_nil
      taro_partner_entry.linked_ex_deal_id.should be_nil
      taro_partner_entry.linked_user_id.should be_nil
      taro_partner_entry.linked_ex_entry_confirmed.should be_false

      # 花子側に連携した取引が記入される
      hanako_deal = @hanako.general_deals.find_by_id(taro_linked_entry.linked_ex_deal_id)
      hanako_deal.should_not be_nil
      hanako_deal.should_not be_confirmed
      hanako_deal.date.should == @taro_deal.date
      hanako_deal.summary.should == @taro_deal.summary
      # 花子側の記入が基本的に正しい
      hanako_linked_entry = hanako_deal.creditor_entries.first
      hanako_linked_entry.amount.should == taro_linked_entry.amount * -1
      hanako_linked_entry.account_id.should == @hanako_taro.id
      # 花子側の記入に連携情報が入る
      hanako_linked_entry.linked_ex_deal_id.should == @taro_deal.id
      hanako_linked_entry.linked_ex_entry_id.should == taro_linked_entry.id
      hanako_linked_entry.linked_user_id.should == @taro.id
      hanako_linked_entry.linked_ex_entry_confirmed.should be_true
      # 花子側の相手記入が正しい
      hanako_partner_entry = hanako_deal.debtor_entries.first
      hanako_partner_entry.account_id.should == @hanako.default_asset.id
      hanako_partner_entry.amount.should == taro_linked_entry.amount
    end

    it "シンプルな両面連携取引が作成できること" do
      prepare_simpe_taro_deal_with_two_links
      lambda{@taro_deal.save!}.should_not raise_error

      # 対応する取引が作成される
      @home_deal = @home.linked_deal_for(@taro.id, @taro_deal.id)
      @home_deal.should_not be_nil

      # 対応する取引内のそれぞれの記入が対応する
      taro_home_cost_entry = @taro_deal.debtor_entries.first
      taro_home_entry = @taro_deal.creditor_entries.first

      home_taro_entry = @home_deal.debtor_entries.first
      home_income_from_two_entry = @home_deal.creditor_entries.first

      taro_home_cost_entry.linked_ex_entry_id.should == home_income_from_two_entry.id
      taro_home_cost_entry.linked_ex_deal_id.should == @home_deal.id
      taro_home_cost_entry.linked_user_id.should == @home.id
      taro_home_cost_entry.linked_ex_entry_confirmed.should be_false

      taro_home_entry.linked_ex_entry_id.should == home_taro_entry.id
      taro_home_entry.linked_ex_deal_id.should == @home_deal.id
      taro_home_entry.linked_user_id == @home.id
      taro_home_entry.linked_ex_entry_confirmed.should be_false

      home_taro_entry.linked_ex_entry_id.should == taro_home_entry.id
      home_taro_entry.linked_ex_deal_id.should == @taro_deal.id
      home_taro_entry.linked_user_id.should == @taro.id
      home_taro_entry.linked_ex_entry_confirmed.should be_true

      home_income_from_two_entry.linked_ex_entry_id.should == taro_home_cost_entry.id
      home_income_from_two_entry.linked_ex_deal_id.should == @taro_deal.id
      home_income_from_two_entry.linked_user_id.should == @taro.id
      home_income_from_two_entry.linked_ex_entry_confirmed.should be_true
    end

    describe "複数のユーザーに連携する複雑な取引" do
      before do
        # 太郎と花子から借りた
        @home_deal = @home.general_deals.build(
          :summary => 'complex',
          :date => Date.today,
          :debtor_entries_attributes => [{:account_id => @home_cache.id, :amount => 10000}],
          :creditor_entries_attributes => [{:account_id => @home_taro.id, :amount => -4000}, {:account_id => @home_hanako.id, :amount => -6000}]
        )
        raise "creditor_entries must be 2" unless @home_deal.creditor_entries.size == 2
      end
      it "作成できる" do
        @home_deal.valid?
        lambda{@home_deal.save!}.should_not raise_error
        home_taro_entry = @home_deal.creditor_entries.find_by_account_id(@home_taro.id)
        home_hanako_entry = @home_deal.creditor_entries.find_by_account_id(@home_hanako.id)
        @taro_deal = @taro.linked_deal_for(@home.id, @home_deal.id)
        @taro_deal.should_not be_nil
        @hanako_deal = @hanako.linked_deal_for(@home.id, @home_deal.id)
        @hanako_deal.should_not be_nil
        taro_linked_entry = @taro_deal.debtor_entries.first
        hanako_linked_entry = @hanako_deal.debtor_entries.first
        # 家計側の太郎への記入
        home_taro_entry.linked_ex_entry_id.should == taro_linked_entry.id
        home_taro_entry.linked_ex_deal_id.should == @taro_deal.id
        home_taro_entry.linked_user_id.should == @taro.id
        home_taro_entry.linked_ex_entry_confirmed.should be_false
        # 太郎側の家計側の記入
        taro_linked_entry.linked_ex_entry_id.should == home_taro_entry.id
        taro_linked_entry.linked_ex_deal_id.should == @home_deal.id
        taro_linked_entry.linked_user_id.should == @home.id
        taro_linked_entry.linked_ex_entry_confirmed.should be_true
        # 太郎側の相手側の記入
        taro_partner_entry = @taro_deal.creditor_entries.first
        taro_partner_entry.amount.should == taro_linked_entry.amount * -1
        taro_partner_entry.linked_ex_entry_id.should be_nil
        # 家計側の花子への記入
        home_hanako_entry.linked_ex_entry_id.should == hanako_linked_entry.id
        home_hanako_entry.linked_ex_deal_id.should == @hanako_deal.id
        home_hanako_entry.linked_user_id.should == @hanako.id
        home_hanako_entry.linked_ex_entry_confirmed.should be_false
        # TODO: 花子側の家計側の記入、花子側の相手側の記入
      end

    end


  end

  describe "update" do
    describe "シンプルな片面連携取引があるとき" do
      before do
        prepare_simple_taro_deal_with_one_link
        @taro_deal.save!
        @hanako_deal = @hanako.linked_deal_for(@taro.id, @taro_deal.id)
        raise "no @hanako_deal" unless @hanako_deal
      end

      it "相手が確認したら、linked_ex_entry_confirmedが更新される" do
        taro_linked_entry = @taro_deal.debtor_entries.first
        raise "前提エラー：相手が未確認ということになっていない" if taro_linked_entry.linked_ex_entry_confirmed
        @hanako_deal.confirm!
        taro_linked_entry.reload
        taro_linked_entry.linked_ex_entry_confirmed.should be_true
      end

      # 一方向リンクのとき、destination_accountがないのに使っている不具合(#187)があったのでその確認スペック
      it "taroからhanakoへのみ一方向に連携しているとき、連動して記入されたhanako側を確認したら、taro側に通知されること" do
        @hanako_taro.link = nil
        @hanako_taro.reload
        @hanako_deal.confirm!
        @taro_deal.reload
        taro_linked_entry = @taro_deal.debtor_entries.first
        taro_linked_entry.linked_ex_entry_confirmed.should be_true
      end

      describe "相手が確認済みでないとき" do
        it "相手が消したら自分のリンク情報が更新される" do
          @hanako_deal.destroy
          @taro_deal.reload
          @taro_deal.debtor_entries.first.linked_ex_entry_id.should be_nil
        end
        it "entriesをロードしていないまま相手が消したら自分のリンク情報が更新される" do
          @hanako_deal.reload # entries がキャッシュされていない状態にする
          @hanako_deal.destroy
          @taro_deal.reload
          @taro_deal.debtor_entries.first.linked_ex_entry_id.should be_nil
        end
        it "相手から自分が連携しないとき、相手が消したら自分のリンク情報が更新される" do
          @hanako_taro.link.destroy
          @hanako_deal.destroy
          @taro_deal.reload
          @taro_deal.debtor_entries.first.linked_ex_entry_id.should be_nil
        end
        it "自分の連携情報がなにかの理由でなくなった場合に、変更したら復活する" do
          @taro_deal.unlink_entries(@hanako.id, @hanako_deal.id)
          @taro_deal.reload
          @taro_deal.save!
          @taro_deal.reload
          @taro.linked_deal_for(@hanako.id, @hanako_deal.id).should_not be_nil
        end

        it "金額を変更したら、相手のdealが削除された上で新しく作られる" do
          @taro_deal.attributes =  {:summary => 'test', :date => Date.today,
            :creditor_entries_attributes => {'1' => {:account_id => @taro_cache.id, :amount => -320}},
            :debtor_entries_attributes => {'1' => {:account_id => @taro_hanako.id, :amount => 320}}
          }
          @taro_deal.save!
          Deal::General.find_by_id(@hanako_deal.id).should be_nil
          @hanako.linked_deal_for(@taro.id, @taro_deal.id).should_not be_nil
        end

        it "連携がなくなる変更をしたら、相手のdealが消される" do
          # taro_hanakoを taro_foodにする変更
          @taro_deal.attributes = {
            :debtor_entries_attributes => [{:account_id => Fixtures.identify(:taro_food), :amount => 300}],
            :creditor_entries_attributes => [{:account_id => @taro_cache.id, :amount => -300}]
          }
          @taro_deal.save!
          @taro_deal.reload

          @hanako.linked_deal_for(@taro.id, @taro_deal.id).should be_nil
        end
      end


      describe "相手が確認済みのとき" do
        before do
          @hanako_deal.confirm!
        end

        it "金額を変更したら相手とのリンクが切られて新しく記入される" do
          @taro_deal.attributes = {
            :creditor_entries_attributes => [{:account_id => @taro_cache.id, :amount => -500}],
            :debtor_entries_attributes => [{:account_id => @taro_hanako.id, :amount => 500}]
          }
          lambda{@taro_deal.save!}.should_not raise_error

          @taro_deal.reload

          new_hanako_deal = @hanako.linked_deal_for(@taro.id, @taro_deal.id)
          new_hanako_deal.should_not be_nil
          new_hanako_deal.id.should_not == @hanako_deal.id

          # 新しいほうとリンクしていることの確認
          # 花子側
          taro_linked_entry = @taro_deal.debtor_entries.first
          new_hanako_linked_entry = new_hanako_deal.creditor_entries.first
          new_hanako_linked_entry.linked_ex_entry_id.should == taro_linked_entry.id
          new_hanako_linked_entry.linked_ex_deal_id.should == @taro_deal.id
          new_hanako_linked_entry.linked_ex_entry_confirmed.should be_true
          new_hanako_linked_entry.linked_user_id.should == @taro.id
          # 太郎側
          taro_linked_entry.linked_ex_entry_id.should == new_hanako_linked_entry.id
          taro_linked_entry.linked_ex_deal_id.should == new_hanako_deal.id
          taro_linked_entry.linked_ex_entry_confirmed.should be_false
          taro_linked_entry.linked_user_id.should == @hanako.id

          # 古いほうのリンクが切れていることの確認
          # 花子側
          old_hanako_linked_entry = @hanako_deal.debtor_entries.first
          old_hanako_linked_entry.linked_ex_entry_id.should be_nil
          old_hanako_linked_entry.linked_ex_deal_id.should be_nil
          old_hanako_linked_entry.linked_user_id.should be_nil
          old_hanako_linked_entry.linked_ex_entry_confirmed.should be_false
        end
      end
    end
  end

  describe "linked_receiver_ids" do
    describe "シンプルな片面連携のとき" do
      before do
        prepare_simple_taro_deal_with_one_link
        @taro_deal.save!
      end

      it "正しく取得できる" do
        @taro_deal.send('linked_receiver_ids').should == [@hanako.id]
      end
    end
  end

  describe "destroy" do
    describe "シンプルな片面連携取引" do
      before do
        prepare_simple_taro_deal_with_one_link
        @taro_deal.save!
        @hanako_deal = @hanako.linked_deal_for(@taro.id, @taro_deal.id)
        raise "no @hanako_deal" unless @hanako_deal
      end
      it "連携したDealの片方を消したら確認してない相手のdealも消される" do
        @taro_deal.destroy
        Deal::General.find_by_id(@hanako_deal.id).should be_nil
      end
      it "連携したDealの片方を消したら確認している相手とのリンクが消される" do
        @hanako_deal.confirm!
        @taro_deal.destroy
        @hanako_deal.reload
        @hanako_unlinked_entry = @hanako_deal.entries.detect{|e| e.account_id == @hanako_taro.id}
        @hanako_unlinked_entry.reload
        @hanako_unlinked_entry.linked_ex_entry_id.should be_nil
        @hanako_unlinked_entry.linked_ex_deal_id.should be_nil
        @hanako_unlinked_entry.linked_user_id.should be_nil
        @hanako_unlinked_entry.linked_ex_entry_confirmed.should be_false
      end
    end
  end

  private
  def prepare_simple_taro_deal_with_one_link
    @taro_deal = @taro.general_deals.build(:summary => 'test', :date => Date.today,
      :creditor_entries_attributes => [{:account_id => @taro_cache.id, :amount => -300}],
      :debtor_entries_attributes => [{:account_id => @taro_hanako.id, :amount => 300}]
    )
  end

  def prepare_simpe_taro_deal_with_two_links
    # taro_home と taro_home_cost
    @taro_deal = @taro.general_deals.build(:summary => "test", :date => Date.today,
      :debtor_entries_attributes => [{:account_id => @taro_home_cost.id, :amount => 300}],
      :creditor_entries_attributes => [{:account_id => @taro_home.id, :amount => -300}])
  end

end