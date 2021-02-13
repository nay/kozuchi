require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Deal::Balance do
  fixtures :users, :accounts

  describe "#valid?" do
    context "account_idがないとき" do
      let(:deal) { build(:balance_deal, :account_id => nil) }
      it "検証エラーとなる" do
        deal.valid?
        expect(deal.errors[:'entry.account_id']).not_to be_empty
      end
    end
    describe "balance" do
      context "ないとき" do
        let(:deal) { build(:balance_deal, :balance => nil) }
        it "検証エラーとなる" do
          deal.valid?
          expect(deal.errors[:'entry.balance']).not_to be_empty
        end
      end
      context "'foo'が入っているとき" do
        let(:deal) { build(:balance_deal, :balance => 'foo') }
        it "検証エラーとなる" do
          deal.valid?
          expect(deal.errors[:'entry.balance']).not_to be_empty
        end
      end
      context "'1.1'が入っているとき" do
        let(:deal) { build(:balance_deal, :balance => '1.1') }
        it "検証エラーとなる" do
          deal.valid?
          expect(deal.errors[:'entry.balance']).not_to be_empty
        end
      end
    end
    context "dateがないとき" do
      let(:deal) { build(:balance_deal, :date => nil) }
      it "検証エラーとなる" do
        deal.valid?
        expect(deal.errors[:date]).not_to be_empty
      end
    end
  end

  describe "#summary" do
    let(:deal) { build(:balance_deal) }
    context "初回残高記入の場合" do
      before do
        deal.entry.initial_balance = true
      end
      it do
        expect(deal.summary).to eq "残高確認（初回）"
      end
    end
    context "初回残高記入でない場合" do
      before do
        deal.entry.initial_balance = false
      end
      it do
        expect(deal.summary).to eq "残高確認"
      end
    end
  end

  describe "#save (create)" do
    context "balanceに'foo'が入っている場合" do
      let(:deal) { build(:balance_deal, :balance => 'foo') }
      it "saveに失敗する（Dealだけ保存されたりしない）" do
        expect(deal.save).to be_falsey
      end
    end

    context "太郎の現金残高800円（初期残高）の場合" do
      let(:deal) { build(:balance_deal, :balance => '800') }
      
      it "成功する" do
        expect(deal.save).to be_truthy
      end
      
      context "成功後" do
        before do
          deal.save!
        end
        
        it "適切なentryがある" do
          expect(deal.entry).not_to be_nil
          deal.entry.kind_of?(Entry::Balance)
          expect(deal.entry).not_to be_new_record
          expect(deal.entry.date).to eq deal.date
          expect(deal.entry.daily_seq).to eq deal.daily_seq
          expect(deal.entry.user_id).to eq deal.user_id
        end
      end
    end

    context "コンマ付き文字列でbalanceを入れたとき" do
      let(:deal) { create(:balance_deal, :balance => '30,333') }
      it "entryに正しいbalanceが入る" do
        expect(deal.entry.balance).to eq 30333
      end
      it "dealからも正しいbalanceが取得できる" do
        expect(deal.balance).to eq 30333
      end
    end

    context "user_idがないとき" do
      let(:deal) { build(:balance_deal, :user_id => nil) }
      it "例外が発生する" do
        expect { deal.save }.to raise_error(RuntimeError)
      end
    end

    describe "amountの計算" do
      context "2012/4/1 に記入 現金→食費 1000円があるとき" do
        let!(:general_deal_1) { create(
            :general_deal,
            :date => Date.new(2012, 4, 1),
            :debtor_entries_attributes => [:account_id => Fixtures.identify(:taro_food), :amount => 1000],
            :creditor_entries_attributes => [:account_id => Fixtures.identify(:taro_cache), :amount => -1000]
        )}
        context "2012/3/3に初期残高 100円を登録する場合" do
          let!(:balance_deal) { create(:balance_deal, :balance => 100, :date => Date.new(2012, 3, 3)) }
          it "amount は 100" do
            expect(balance_deal.amount).to eq 100
          end
          it "initial_balanceである" do
            expect(balance_deal.entry).to be_initial_balance
          end
        end
        context "2012/5/1に初期残高 100円を登録する場合" do
          let!(:balance_deal) { create(:balance_deal, :balance => 100, :date => Date.new(2012, 5, 1)) }
          it "amount は 1100" do
            expect(balance_deal.amount).to eq 1100
          end
          it "initial_balanceである" do
            expect(balance_deal.entry).to be_initial_balance
          end
        end
        context "2012/1/1に初期残高 10000円が登録ずみの場合" do
          let!(:initial_balance) { create(:balance_deal, :balance => 10000, :date => Date.new(2012, 1, 1)) }

          context "2012/4/2 に残高記入が 9000円（不明なし）がある場合" do
            let!(:balance_deal) { create(:balance_deal, :balance => 9000, :date => Date.new(2012, 4, 2)) }
            it "amount は 0" do
              expect(balance_deal.amount).to eq 0
            end
            it "initial balanceでない" do
              expect(balance_deal.entry).not_to be_initial_balance
            end
          end
          context "2012/4/2 に残高記入が 7000円（予測より2000円少ない）がある場合" do
            let!(:balance_deal) { create(:balance_deal, :balance => 7000, :date => Date.new(2012, 4, 2)) }
            it "amount は -2000" do
              expect(balance_deal.amount).to eq -2000
            end
            it "initial balanceでない" do
              expect(balance_deal.entry).not_to be_initial_balance
            end

            context "初期残高が削除されたとき" do
              before do
                initial_balance.destroy
                balance_deal.reload
              end
              it "balanceは変化しない" do
                expect(balance_deal.balance).to eq 7000
              end
              it "amountが 8000円に変わっている" do
                expect(balance_deal.amount).to eq 8000
              end
              it "initial_balanceになる" do
                expect(balance_deal.entry).to be_initial_balance
              end
            end
          end
          context "2012/4/2 に残高記入が 9500円（予測より500円多い）がある場合" do
            let!(:balance_deal) { create(:balance_deal, :balance => 9500, :date => Date.new(2012, 4, 2)) }
            it "amount は 500" do
              expect(balance_deal.amount).to eq 500
            end
            it "initial balanceでない" do
              expect(balance_deal.entry).not_to be_initial_balance
            end
            context "初期残高が削除されたとき" do
              before do
                initial_balance.destroy
                balance_deal.reload
              end
              it "balanceは変化しない" do
                expect(balance_deal.balance).to eq 9500
              end
              it "amountが 10500円に変わっている" do
                expect(balance_deal.amount).to eq 10500
              end
              it "initial_balanceになる" do
                expect(balance_deal.entry).to be_initial_balance
              end
            end
          end
          context "2011/12/10 に新たな初期残高 500円が登録された場合（次の記入は残高10000円）" do
            let!(:balance_deal) { create(:balance_deal, :balance => 500, :date => Date.new(2011, 12, 10)) }
            let!(:old_initial) { initial_balance.reload; initial_balance }
            it "initial_balanceである" do
              expect(balance_deal.entry).to be_initial_balance
            end
            it "amountは500" do
              expect(balance_deal.amount).to eq 500
            end
            it "2012/1/1の残高はinitial_balanceでない" do
              expect(old_initial.entry).not_to be_initial_balance
            end
            it "2012/1/1の残高のamountは9500に変わる" do
              expect(old_initial.amount).to eq 9500
            end
          end
        end
      end
    end
  end

  describe "#save (update)" do
    let!(:balance_deal) { create(:balance_deal, :balance => 1000, :date => Date.new(2012, 4, 1)) }

    it "日付を変えたらentryも追随する" do
      balance_deal.date += 1
      expect(balance_deal.save).to be_truthy
      balance_deal.reload
      expect(balance_deal.entry.date.to_s).to eq Date.new(2012, 4, 2).to_s
    end

    context "initialだったBalanceをinitialじゃない位置に移動したとき" do
      let!(:balance_deal_2) { create(:balance_deal, :balance => 1333, :date => Date.new(2012, 4, 3)) }
      before do
        # 前提
        raise "not initial balance" unless balance_deal.entry.initial_balance?
        raise "amount is not 1000" unless balance_deal.entry.amount == 1000

        # 前提：２つめの残高のamount は333 になっているはず
        raise "amount is not 333" unless balance_deal_2.entry.amount == 333

        # この時点で以下のようになっていることを想定する
        #           記入   amount
        # balance   1000   1000 (initial)
        # balance2  1333   333

        # balanceをbalance2の後に移動する
        balance_deal.date = balance_deal_2.date + 1
        balance_deal.save!
        balance_deal.reload
        balance_deal_2.reload
      end
      it "amountが正しく変更される" do
        # 以下のようになることを想定する
        #           記入   amount
        # balance2  1333   1333    (initial)
        # balance   1000   -333
        expect(balance_deal_2.entry.amount).to eq 1333
        expect(balance_deal.entry.amount).to eq -333
        expect(balance_deal_2.entry).to be_initial_balance
        expect(balance_deal.entry).not_to be_initial_balance
      end
    end

  end

  describe "#destroy" do
    let!(:balance_deal) { create(:balance_deal, :balance => 1000, :date => Date.new(2012, 4, 1)) }

    it "削除できる" do
      expect { balance_deal.destroy }.not_to raise_error
    end
  end
end
