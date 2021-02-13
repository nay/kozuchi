# 連携機能に特化したスペック

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Deal Linking" do
  fixtures :accounts, :account_links, :account_link_requests, :friend_requests, :friend_permissions, :users

  let(:taro) { users(:taro) }
  let(:hanako) { users(:hanako) }
  before do
    @taro = taro # TODO: @taro は削除したい
    @hanako = hanako # TODO: @hanako は削除したい
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
      expect{ @taro_deal.save! }.not_to raise_error
      # 太郎側の記入に連携情報が入る
      taro_linked_entry = @taro_deal.debtor_entries.first
      expect(taro_linked_entry.linked_ex_deal_id).not_to be_nil
      expect(taro_linked_entry.linked_ex_entry_id).not_to be_nil
      expect(taro_linked_entry.linked_ex_entry_confirmed).to be_falsey
      expect(taro_linked_entry.linked_user_id).to eq @hanako.id
      # 太郎側の相手記入には連携情報が入らない
      taro_partner_entry = @taro_deal.creditor_entries.first
      expect(taro_partner_entry.linked_ex_entry_id).to be_nil
      expect(taro_partner_entry.linked_ex_deal_id).to be_nil
      expect(taro_partner_entry.linked_user_id).to be_nil
      expect(taro_partner_entry.linked_ex_entry_confirmed).to be_falsey

      # 花子側に連携した取引が記入される
      hanako_deal = @hanako.general_deals.find_by(id: taro_linked_entry.linked_ex_deal_id)
      expect(hanako_deal).not_to be_nil
      expect(hanako_deal).not_to be_confirmed
      expect(hanako_deal.date).to eq @taro_deal.date
      expect(hanako_deal.summary).to eq @taro_deal.summary
      # 花子側の記入が基本的に正しい
      hanako_linked_entry = hanako_deal.creditor_entries.first
      expect(hanako_linked_entry.amount).to eq taro_linked_entry.amount * -1
      expect(hanako_linked_entry.account_id).to eq @hanako_taro.id
      # 花子側の記入に連携情報が入る
      expect(hanako_linked_entry.linked_ex_deal_id).to eq @taro_deal.id
      expect(hanako_linked_entry.linked_ex_entry_id).to eq taro_linked_entry.id
      expect(hanako_linked_entry.linked_user_id).to eq @taro.id
      expect(hanako_linked_entry.linked_ex_entry_confirmed).to be_truthy
      # 花子側の相手記入が正しい
      hanako_partner_entry = hanako_deal.debtor_entries.first
      expect(hanako_partner_entry.account_id).to eq @hanako.default_asset.id
      expect(hanako_partner_entry.amount).to eq taro_linked_entry.amount
    end

    it "シンプルな両面連携取引が作成できること" do
      prepare_simpe_taro_deal_with_two_links
      expect{ @taro_deal.save! }.not_to raise_error

      # 対応する取引が作成される
      @home_deal = @home.linked_deal_for(@taro.id, @taro_deal.id)
      expect(@home_deal).not_to be_nil

      # 対応する取引内のそれぞれの記入が対応する
      taro_home_cost_entry = @taro_deal.debtor_entries.first
      taro_home_entry = @taro_deal.creditor_entries.first

      home_taro_entry = @home_deal.debtor_entries.first
      home_income_from_two_entry = @home_deal.creditor_entries.first

      expect(taro_home_cost_entry.linked_ex_entry_id).to eq home_income_from_two_entry.id
      expect(taro_home_cost_entry.linked_ex_deal_id).to eq @home_deal.id
      expect(taro_home_cost_entry.linked_user_id).to eq @home.id
      expect(taro_home_cost_entry.linked_ex_entry_confirmed).to be_falsey

      expect(taro_home_entry.linked_ex_entry_id).to eq home_taro_entry.id
      expect(taro_home_entry.linked_ex_deal_id).to eq @home_deal.id
      expect(taro_home_entry.linked_user_id).to eq @home.id
      expect(taro_home_entry.linked_ex_entry_confirmed).to be_falsey

      expect(home_taro_entry.linked_ex_entry_id).to eq taro_home_entry.id
      expect(home_taro_entry.linked_ex_deal_id).to eq @taro_deal.id
      expect(home_taro_entry.linked_user_id).to eq @taro.id
      expect(home_taro_entry.linked_ex_entry_confirmed).to be_truthy

      expect(home_income_from_two_entry.linked_ex_entry_id).to eq taro_home_cost_entry.id
      expect(home_income_from_two_entry.linked_ex_deal_id).to eq @taro_deal.id
      expect(home_income_from_two_entry.linked_user_id).to eq @taro.id
      expect(home_income_from_two_entry.linked_ex_entry_confirmed).to be_truthy
    end

    context "サマリー分割モードで記入された連携Entryを１つ含む複数明細" do
      let(:deal) {
        new_complex_deal(7, 15, [[:taro_food, 800, 'ラーメン'], [:taro_food, 500, '菓子']], [[:taro_hanako, -800, '[太郎]ラーメン'], [:taro_cache, -500, '菓子']])
      }

      describe "valid?" do
        it { expect(deal.valid?).to be_truthy }
      end

      describe "save (create)" do
        it "登録が成功し、正しいサマリーが連携記入に含まれる" do
          expect(deal.save).to be_truthy
          linked_deal = hanako.linked_deal_for(taro.id, deal.id)
          expect(linked_deal).not_to be_nil
          # 花子側の借方に連携が入る
          expect(linked_deal.debtor_entries.map(&:summary)).to eq ['[太郎]ラーメン']
          # 花子側の貸し方にも同じものがはいる
          expect(linked_deal.creditor_entries.map(&:summary)).to eq ['[太郎]ラーメン']
        end
      end

      describe "save (update)" do
        before do
          deal.save!
        end

        context "一度保存して連携取引ができたあと、splitモードのまま、一部のサマリーを変えたとき" do
          before do
            deal.attributes = {
                :debtor_entries_attributes => deal.debtor_entries.map{|e| {:account_id => e.account_id, :amount => e.amount, :id => e.id, :line_number => e.line_number, :summary => e.summary}},
                :creditor_entries_attributes => deal.creditor_entries.map{|e| {:account_id => e.account_id, :amount => e.amount, :id => e.id, :line_number => e.line_number, :summary => e.summary == '[太郎]ラーメン' ? '[太郎]味噌ラーメン' : e.summary}}
            }
          end
          it "更新が成功し、変更後のサマリーが連携記入に含まれる" do
            expect(deal.save).to be_truthy
            linked_deal = hanako.linked_deal_for(taro.id, deal.id)
            expect(linked_deal).not_to be_nil
            # 花子側の借方に連携が入る
            expect(linked_deal.debtor_entries.map(&:summary)).to eq ['[太郎]味噌ラーメン']
            # 花子側の貸し方にも同じサマリーがはいる
            expect(linked_deal.creditor_entries.map(&:summary)).to eq ['[太郎]味噌ラーメン']
          end
        end

        context "一度保存して連携取引ができたあと、unifyモードにしてサマリーを変えたとき" do
          before do
            deal.attributes = {
                :summary_mode => 'unify',
                :summary => 'ラーメンと菓子',
                :debtor_entries_attributes => deal.debtor_entries.map{|e| {:account_id => e.account_id, :amount => e.amount, :id => e.id, :line_number => e.line_number}},
                :creditor_entries_attributes => deal.creditor_entries.map{|e| {:account_id => e.account_id, :amount => e.amount, :id => e.id, :line_number => e.line_number}}
            }
          end
          it "更新が成功し、変更後のサマリーが連携記入に含まれる" do
            expect(deal.save).to be_truthy
            linked_deal = hanako.linked_deal_for(taro.id, deal.id)
            expect(linked_deal).not_to be_nil
            # 花子側の借方に連携が入る
            expect(linked_deal.debtor_entries.map(&:summary)).to eq ['ラーメンと菓子']
            expect(linked_deal.summary_unified?).to be_truthy
            # 花子側の貸し方にも同じサマリーが入る
            expect(linked_deal.creditor_entries.map(&:summary)).to eq ['ラーメンと菓子']
          end
        end
      end
    end

    context "サマリー分割モードで記入された連携Entryを２つ含む複数明細" do
      let(:deal) {
        new_complex_deal(7, 15, [[:taro_food, 800, 'ラーメン'], [:taro_food, 500, '菓子']], [[:taro_hanako, -800, '[太郎]ラーメン'], [:taro_hanako, -500, '[太郎]菓子']])
      }

      describe "valid?" do
        it { expect(deal.valid?).to be_truthy }
      end

      describe "save (create)" do
        it "登録が成功し、正しいサマリーが連携記入に含まれる" do
          expect(deal.save).to be_truthy
          linked_deal = hanako.linked_deal_for(taro.id, deal.id)
          expect(linked_deal).not_to be_nil
          # 花子側の借方に連携が入る
          expect(linked_deal.debtor_entries.map(&:summary)).to eq ['[太郎]ラーメン', '[太郎]菓子']
          # 花子側の貸し方には最初の１つに「、他」をつけたサマリーがはいる
          expect(linked_deal.creditor_entries.map(&:summary)).to eq ['[太郎]ラーメン、他']
        end
      end

      describe "save (update)" do
        before do
          deal.save!
        end

        context "一度保存して連携取引ができたあと、splitモードのまま、一部のサマリーを変えたとき" do
          before do
            deal.attributes = {
              :debtor_entries_attributes => deal.debtor_entries.map{|e| {:account_id => e.account_id, :amount => e.amount, :id => e.id, :line_number => e.line_number, :summary => e.summary}},
              :creditor_entries_attributes => deal.creditor_entries.map{|e| {:account_id => e.account_id, :amount => e.amount, :id => e.id, :line_number => e.line_number, :summary => e.summary == '[太郎]ラーメン' ? new_summary : e.summary}}
            }
          end
          context "変更後のサマリーが10文字のとき" do
            let(:new_summary) { '[太郎]味噌ラーメン' }
            it "更新が成功し、変更後のサマリーが連携記入に含まれる" do
              expect(deal.save).to be_truthy
              linked_deal = hanako.linked_deal_for(taro.id, deal.id)
              expect(linked_deal).not_to be_nil
              # 花子側の借方に連携が入る
              expect(linked_deal.debtor_entries.map(&:summary)).to eq ['[太郎]味噌ラーメン', '[太郎]菓子']
              # 花子側の貸し方には最初の１つに「、他」をつけたサマリーがはいる
              expect(linked_deal.creditor_entries.map(&:summary)).to eq ['[太郎]味噌ラーメン、他']
            end
          end
          context "変更後のサマリーが64文字のとき" do
            let(:new_summary) { '＊' * 64 }
            it "更新が成功し、変更後のサマリーが連携記入に含まれる" do
              expect(deal.save).to be_truthy
              linked_deal = hanako.linked_deal_for(taro.id, deal.id)
              expect(linked_deal).not_to be_nil
              # 花子側の借方に連携が入る
              expect(linked_deal.debtor_entries.map(&:summary)).to eq [new_summary, '[太郎]菓子']
              # 花子側の貸し方には最初の１つをtruncateして「、他」をつけたサマリーがはいる
              expect(linked_deal.creditor_entries.map(&:summary)).to eq ["#{'＊' * 59}...、他"]
            end
          end
        end

        context "一度保存して連携取引ができたあと、unifyモードにしてサマリーを変えたとき" do
          before do
            deal.attributes = {
              :summary_mode => 'unify',
              :summary => 'ラーメンと菓子',
              :debtor_entries_attributes => deal.debtor_entries.map{|e| {:account_id => e.account_id, :amount => e.amount, :id => e.id, :line_number => e.line_number}},
              :creditor_entries_attributes => deal.creditor_entries.map{|e| {:account_id => e.account_id, :amount => e.amount, :id => e.id, :line_number => e.line_number}}
            }
          end
          it "更新が成功し、変更後のサマリーが連携記入に含まれる" do
            expect(deal.save).to be_truthy
            linked_deal = hanako.linked_deal_for(taro.id, deal.id)
            expect(linked_deal).not_to be_nil
            # 花子側の借方に連携が入る
            expect(linked_deal.debtor_entries.map(&:summary)).to eq ['ラーメンと菓子', 'ラーメンと菓子']
            expect(linked_deal.summary_unified?).to be_truthy
            # 花子側の貸し方にも同じサマリーが入る
            expect(linked_deal.creditor_entries.map(&:summary)).to eq ['ラーメンと菓子']
          end
        end
      end
    end

    describe "両面取引" do
      before do
        prepare_simpe_taro_deal_with_two_links
        @taro_deal.save!

        # 対応する取引が作成される
        @home_deal = @home.linked_deal_for(@taro.id, @taro_deal.id)
        raise "対応する取引が作成されていない" unless @home_deal
      end
      it "相手の取引を確認しても、リンク状態が壊れないこと" do
        # 確認する
        @home_deal.confirm!

        # リンク状態が壊れていないこと
        @taro_deal.reload
        expect(@taro.linked_deal_for(@home.id, @home_deal)).to eq @taro_deal
        expect(@home.linked_deal_for(@taro.id, @taro_deal)).to eq @home_deal
      end

      it "相手が確認する前に摘要を変えたら摘要が変わること" do
        @taro_deal.summary = "やっぱ変えました"
        @taro_deal.save!

        @home_deal.reload
        expect(@home.linked_deal_for(@taro.id, @taro_deal)).to eq @home_deal
        expect(@home_deal.summary).to eq "やっぱ変えました"
      end
      it "相手が確認する前に日にちを変えたら日にちが変わること" do
        @taro_deal.date = @taro_deal.date + 3
        @taro_deal.save!

        @home_deal.reload
        expect(@home.linked_deal_for(@taro.id, @taro_deal)).to eq @home_deal
        expect(@home_deal.date).to eq @taro_deal.date
      end
    end


    describe "複数のユーザーに連携する複雑な取引" do
      before do
        # 太郎と花子から借りた
        @home_deal = @home.general_deals.build(
          :summary => 'complex',
          :date => Time.zone.today,
          :debtor_entries_attributes => [{:account_id => @home_cache.id, :amount => 10000, :line_number => 0}],
          :creditor_entries_attributes => [{:account_id => @home_taro.id, :amount => -4000, :line_number => 0}, {:account_id => @home_hanako.id, :amount => -6000, :line_number => 1}]
        )
        raise "creditor_entries must be 2" unless @home_deal.creditor_entries.size == 2
      end
      it "作成できる" do
        @home_deal.valid?
        expect{ @home_deal.save! }.not_to raise_error
        home_taro_entry = @home_deal.creditor_entries.find_by(account_id: @home_taro.id)
        home_hanako_entry = @home_deal.creditor_entries.find_by(account_id: @home_hanako.id)
        @taro_deal = @taro.linked_deal_for(@home.id, @home_deal.id)
        expect(@taro_deal).not_to be_nil
        @hanako_deal = @hanako.linked_deal_for(@home.id, @home_deal.id)
        expect(@hanako_deal).not_to be_nil
        taro_linked_entry = @taro_deal.debtor_entries.first
        hanako_linked_entry = @hanako_deal.debtor_entries.first
        # 家計側の太郎への記入
        expect(home_taro_entry.linked_ex_entry_id).to eq taro_linked_entry.id
        expect(home_taro_entry.linked_ex_deal_id).to eq @taro_deal.id
        expect(home_taro_entry.linked_user_id).to eq @taro.id
        expect(home_taro_entry.linked_ex_entry_confirmed).to be_falsey
        # 太郎側の家計側の記入
        expect(taro_linked_entry.linked_ex_entry_id).to eq home_taro_entry.id
        expect(taro_linked_entry.linked_ex_deal_id).to eq @home_deal.id
        expect(taro_linked_entry.linked_user_id).to eq @home.id
        expect(taro_linked_entry.linked_ex_entry_confirmed).to be_truthy
        # 太郎側の相手側の記入
        taro_partner_entry = @taro_deal.creditor_entries.first
        expect(taro_partner_entry.amount).to eq taro_linked_entry.amount * -1
        expect(taro_partner_entry.linked_ex_entry_id).to be_nil
        # 家計側の花子への記入
        expect(home_hanako_entry.linked_ex_entry_id).to eq hanako_linked_entry.id
        expect(home_hanako_entry.linked_ex_deal_id).to eq @hanako_deal.id
        expect(home_hanako_entry.linked_user_id).to eq @hanako.id
        expect(home_hanako_entry.linked_ex_entry_confirmed).to be_falsey
        # TODO: 花子側の家計側の記入、花子側の相手側の記入
      end

    end

    describe "同じユーザーの同じ口座への記入が複数ある複数明細" do
      let(:deal) do
        # taro_hanako から taro_food へ ×２
        new_complex_deal(7, 15, [[:taro_food, 500], [:taro_food, 800]], [[:taro_hanako, -500], [:taro_hanako, -800]])
      end

      describe "valid?" do
        it { expect(deal.valid?).to be_truthy }
      end

      describe "save" do
        it { expect(deal.save).to be_truthy }
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
        expect(taro_linked_entry.linked_ex_entry_confirmed).to be_truthy
      end

      # 一方向リンクのとき、destination_accountがないのに使っている不具合(#187)があったのでその確認スペック
      it "taroからhanakoへのみ一方向に連携しているとき、連動して記入されたhanako側を確認したら、taro側に通知されること" do
        @hanako_taro.link = nil
        @hanako_taro.reload
        @hanako_deal.confirm!
        @taro_deal.reload
        taro_linked_entry = @taro_deal.debtor_entries.first
        expect(taro_linked_entry.linked_ex_entry_confirmed).to be_truthy
      end

      describe "相手が確認済みでないとき" do
        it "相手が消したら自分のリンク情報が更新される" do
          @hanako_deal.destroy
          @taro_deal.reload
          expect(@taro_deal.debtor_entries.first.linked_ex_entry_id).to be_nil
        end
        it "entriesをロードしていないまま相手が消したら自分のリンク情報が更新される" do
          @hanako_deal.reload # entries がキャッシュされていない状態にする
          @hanako_deal.destroy
          @taro_deal.reload
          expect(@taro_deal.debtor_entries.first.linked_ex_entry_id).to be_nil
        end
        it "相手から自分が連携しないとき、相手が消したら自分のリンク情報が更新される" do
          @hanako_taro.link.destroy
          @hanako_deal.destroy
          @taro_deal.reload
          expect(@taro_deal.debtor_entries.first.linked_ex_entry_id).to be_nil
        end
        it "自分の連携情報がなにかの理由でなくなった場合に、変更したら復活する" do
          @taro_deal.unlink_entries(@hanako.id, @hanako_deal.id)
          @taro_deal.reload
          @taro_deal.save!
          @taro_deal.reload
          expect(@taro.linked_deal_for(@hanako.id, @hanako_deal.id)).not_to be_nil
        end

        it "金額を変更したら、相手のdealが削除された上で新しく作られる" do
          @taro_deal.attributes =  {:summary => 'test', :date => Time.zone.today,
            :creditor_entries_attributes => {'1' => {:account_id => @taro_cache.id, :amount => -320}},
            :debtor_entries_attributes => {'1' => {:account_id => @taro_hanako.id, :amount => 320}}
          }
          @taro_deal.save!
          expect(Deal::General.find_by(id: @hanako_deal.id)).to be_nil
          expect(@hanako.linked_deal_for(@taro.id, @taro_deal.id)).not_to be_nil
        end

        it "連携がなくなる変更をしたら、相手のdealが消される" do
          # taro_hanakoを taro_foodにする変更
          @taro_deal.attributes = {
            :debtor_entries_attributes => [{:account_id => Fixtures.identify(:taro_food), :amount => 300}],
            :creditor_entries_attributes => [{:account_id => @taro_cache.id, :amount => -300}]
          }
          @taro_deal.save!
          @taro_deal.reload

          expect(@hanako.linked_deal_for(@taro.id, @taro_deal.id)).to be_nil
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
          expect{ @taro_deal.save! }.not_to raise_error

          @taro_deal.reload

          new_hanako_deal = @hanako.linked_deal_for(@taro.id, @taro_deal.id)
          expect(new_hanako_deal).not_to be_nil
          expect(new_hanako_deal.id).not_to eq @hanako_deal.id

          # 新しいほうとリンクしていることの確認
          # 花子側
          taro_linked_entry = @taro_deal.debtor_entries.first
          new_hanako_linked_entry = new_hanako_deal.creditor_entries.first
          expect(new_hanako_linked_entry.linked_ex_entry_id).to eq taro_linked_entry.id
          expect(new_hanako_linked_entry.linked_ex_deal_id).to eq @taro_deal.id
          expect(new_hanako_linked_entry.linked_ex_entry_confirmed).to be_truthy
          expect(new_hanako_linked_entry.linked_user_id).to eq @taro.id
          # 太郎側
          expect(taro_linked_entry.linked_ex_entry_id).to eq new_hanako_linked_entry.id
          expect(taro_linked_entry.linked_ex_deal_id).to eq new_hanako_deal.id
          expect(taro_linked_entry.linked_ex_entry_confirmed).to be_falsey
          expect(taro_linked_entry.linked_user_id).to eq @hanako.id

          # 古いほうのリンクが切れていることの確認
          # 花子側
          old_hanako_linked_entry = @hanako_deal.debtor_entries.first
          expect(old_hanako_linked_entry.linked_ex_entry_id).to be_nil
          expect(old_hanako_linked_entry.linked_ex_deal_id).to be_nil
          expect(old_hanako_linked_entry.linked_user_id).to be_nil
          expect(old_hanako_linked_entry.linked_ex_entry_confirmed).to be_falsey
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
        expect(@taro_deal.send('linked_receiver_ids')).to eq [@hanako.id]
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
        expect(Deal::General.find_by(id: @hanako_deal.id)).to be_nil
      end
      it "連携したDealの片方を消したら確認している相手とのリンクが消される" do
        @hanako_deal.confirm!
        @taro_deal.destroy
        @hanako_deal.reload
        @hanako_unlinked_entry = @hanako_deal.entries.detect{|e| e.account_id == @hanako_taro.id}
        @hanako_unlinked_entry.reload
        expect(@hanako_unlinked_entry.linked_ex_entry_id).to be_nil
        expect(@hanako_unlinked_entry.linked_ex_deal_id).to be_nil
        expect(@hanako_unlinked_entry.linked_user_id).to be_nil
        expect(@hanako_unlinked_entry.linked_ex_entry_confirmed).to be_falsey
      end
    end
  end

  private
  def prepare_simple_taro_deal_with_one_link
    @taro_deal = @taro.general_deals.build(:summary => 'test', :summary_mode => 'unify', :date => Time.zone.today,
      :creditor_entries_attributes => [{:account_id => @taro_cache.id, :amount => -300}],
      :debtor_entries_attributes => [{:account_id => @taro_hanako.id, :amount => 300}]
    )
  end

  def prepare_simpe_taro_deal_with_two_links
    # taro_home と taro_home_cost
    @taro_deal = @taro.general_deals.build(:summary => "test", :summary_mode => 'unify', :date => Time.zone.today,
      :debtor_entries_attributes => [{:account_id => @taro_home_cost.id, :amount => 300}],
      :creditor_entries_attributes => [{:account_id => @taro_home.id, :amount => -300}])
  end

end