require 'spec_helper'

describe DealsController, js: true, type: :feature do
  fixtures :users, :accounts, :preferences

  # ↓↓ shared

  # 変更windowを開いたあとの記述。閲覧と記入でまったく同じなのでここで
  shared_examples_for "複数記入に変更できる" do
    before do
      click_link '複数記入にする'
    end
    it "フォーム部分だけが変わる" do
      expect(page).to have_css("select#deal_creditor_entries_attributes_4_account_id")
    end
    it "記入欄を増やせる" do
      click_link '記入欄を増やす'
      expect(page).to have_css("select#deal_creditor_entries_attributes_5_account_id")
    end
  end

  shared_examples_for "変更を実行できる" do
    before do
      find("#date_day[value='10']")
      fill_in 'date_day', :with => '11'
      fill_in 'deal_summary', :with => '冷やし中華'
      fill_in 'deal_debtor_entries_attributes_0_amount', :with => '920'
      select 'クレジットカードＸ', :from => 'deal_creditor_entries_attributes_0_account_id'
      click_button '変更'
    end

    it "一覧に表示される" do
      expect(flash_notice).to have_content("更新しました。")
      expect(flash_notice).to have_content("2012/07/11")
      expect(page).to have_content('冷やし中華')
      expect(page).to have_content('920')
      expect(page).to have_content('クレジットカードＸ')
    end
  end

  shared_examples_for "削除できる" do
    before do
      deal # create
      visit "/deals/2012/7"
      click_link('削除')
    end
    it do
      expect(flash_notice).to have_content("削除しました。")
    end
  end


  # ↑↑ shared

  before do
    Deal::Base.destroy_all
  end

  include_context "太郎 logged in"

  describe "家計簿(閲覧)" do
    before do
      select_menu('家計簿')
    end

    describe "今日エリアのクリック" do
      let(:target_date) {Time.zone.today << 1}
      before do
        # 前月にしておいて
        click_calendar(target_date.year, target_date.month)

        # クリック
        find("#today").click
      end

      it "カレンダーの選択月が今月に変わり、記入日の年月日が変わる" do
        expect(selected_month_text).to eq "#{Time.zone.today.month}月"
        expect(input_date_field_values).to eq [Time.zone.today.year.to_s, Time.zone.today.month.to_s, Time.zone.today.day.to_s]
      end
    end


    describe "カレンダー（翌月）のクリック" do
      let(:target_date) {Time.zone.today >> 1}
      before do
        click_calendar(target_date.year, target_date.month)
      end

      it "カレンダーの選択月が翌月に変わり、記入日の月が変わる" do
        expect(selected_month_text).to eq "#{target_date.month}月"
        expect(find("input#date_month").value).to eq target_date.month.to_s
      end
    end

    describe "カレンダー（翌年）のクリック" do
      before do
        find("#next_year").click
      end
      it "URLに翌年を含み、記入日の年が変わる" do
        expect(current_path =~ /\/#{(Time.zone.today >> 12).year.to_s}\//).to be_truthy
        expect(find("input#date_year").value).to eq (Time.zone.today >> 12).year.to_s
      end
    end

    describe "カレンダー（前年）のクリック" do
      before do
        find("#prev_year").click
      end
      it "URLに前年を含み、記入日の年が変わる" do
        expect(current_path =~ /\/#{(Time.zone.today << 12).year.to_s}\//).to be_truthy
        expect(find("input#date_year").value).to eq (Time.zone.today << 12).year.to_s
      end
    end

    describe "日ナビゲーターのクリック" do
      let(:target_date) {Time.zone.today << 1} # 前月
      before do
        click_calendar(target_date.year, target_date.month)
        # 3日をクリック
        date = Date.new((Time.zone.today << 1).year, target_date.month, 3)
        click_link I18n.l(date, :format => :day).strip # strip しないとマッチしない
      end
      it "URLに対応する日付ハッシュがつき、日の欄に指定した日が入る" do
        expect(current_hash).to eq('day3')
        expect(find("input#date_day").value).to eq '3'
      end
    end

    describe "登録" do
      describe "通常明細" do
        context "日付欄（日）にアルファベットがあるとき" do
          before do
            fill_in 'date_day', with: 'a' # アルファベット
            fill_in 'deal_summary', with: '朝食のおにぎり'
            fill_in 'deal_debtor_entries_attributes_0_amount', with: '210'
            select '現金', :from => 'deal_creditor_entries_attributes_0_account_id'
            select '食費', :from => 'deal_debtor_entries_attributes_0_account_id'
            click_button '記入'
          end

          it "エラーが表示され、入れたままの文字が欄にある" do
            expect(page).to have_content('記入にエラーが発生しました。')
            expect(page).to have_content('日付を入力してください。')
            expect(find("input#date_day").value).to eq 'a'
          end
        end

        describe "金額" do
          before do
            fill_in 'deal_summary', :with => '朝食のおにぎり'
            fill_in 'deal_debtor_entries_attributes_0_amount', :with => amount
            select '現金', :from => 'deal_creditor_entries_attributes_0_account_id'
            select '食費', :from => 'deal_debtor_entries_attributes_0_account_id'
            click_button '記入'
          end

          context "金額が正しいとき" do
            let(:amount) { '210' }
            it "登録できる" do
              expect(flash_notice).to have_content('追加しました。')
              expect(current_hash).to eq "recent"
              expect(page).to have_content('朝食のおにぎり')
            end
          end

          context "金額がアルファベットのとき" do
            let(:amount) { 'abc' }
            it "エラーが表示される" do
              expect(page).to have_content('記入にエラーが発生しました。')
              expect(page).to have_content('金額は数値で入力してください。')
            end
          end

          context "金額の前後に半角スペースが含まれるとき" do
            let(:amount) { ' 210 ' }
            it "登録できる" do
              expect(flash_notice).to have_content('追加しました。')
              expect(current_hash).to eq "recent"
              expect(page).to have_content('朝食のおにぎり')
            end
          end
        end
      end

      describe "通常明細のサジェッション" do
        let(:deal_type) { :general_deal }
        let(:summary) { "朝食のサンドイッチ" }
        let(:suggestion_with_amount) { true }
        before do
          create(deal_type, :card, :date => Time.zone.today, :summary => summary)
          create(deal_type, :cache, :date => Time.zone.today, :summary => summary)

          fill_in 'deal_summary', :with => '朝食'
          expect(page).to have_css("#patterns div.clickable_text") # サジェッションが表示される
          clickable_text_index = suggestion_with_amount ? 0 : 1
          page.all("#patterns div.clickable_text")[clickable_text_index].click # サジェッションをクリック
        end

        context "履歴の摘要に ' がないとき" do
          context "金額ありのとき" do

            it "金額つきでデータが入り、新たにサジェッションが表示されている" do
              expect(page.find("#deal_summary").value).to eq '朝食のサンドイッチ'
              expect(page.find("#deal_debtor_entries_attributes_0_amount").value).not_to be_empty
              expect(page).to have_css("#patterns div.clickable_text")
            end
          end
          context "金額なしのとき" do
            let(:suggestion_with_amount) { false }

            it "金額抜きでデータが入り、新たにサジェッションが表示されている" do
              expect(page.find("#deal_summary").value).to eq '朝食のサンドイッチ'
              expect(page.find("#deal_debtor_entries_attributes_0_amount").value).to be_empty
              expect(page).to have_css("#patterns div.clickable_text")
            end
          end
        end

        context "履歴の摘要に ' があるとき" do
          let(:summary) { "朝食の'サンドイッチ'" }

          context "金額ありのとき" do

            it "金額つきでデータが入り、新たにサジェッションが表示されている" do
              expect(page.find("#deal_summary").value).to eq "朝食の'サンドイッチ'"
              expect(page).to have_css("#patterns div.clickable_text")
            end
          end

          # 金額なしは ' のないケースと同じなので省略する
        end

        context "履歴が複数明細のとき" do
          let(:deal_type) { :complex_deal }

          context "金額ありのとき" do

            it "金額つきでデータが入り、新たにサジェッションが表示されている" do
              expect(page).to have_css('#deal_creditor_entries_attributes_0_reversed_amount') # Ajaxで、呼び出し前から deal_summary があるため、ほかの欄の登場を待つ
              expect(page.find("#deal_summary").value).to eq '朝食のサンドイッチ'
              expect(page.find('#deal_creditor_entries_attributes_0_reversed_amount').value).not_to be_empty
              expect(page).to have_css("#patterns div.clickable_text")
            end
          end

          context "金額なしのとき" do
            let(:suggestion_with_amount) { false }

            it "金額抜きでデータが入り、新たにサジェッションが表示されている" do
              expect(page).to have_css('#deal_creditor_entries_attributes_0_reversed_amount') # Ajaxで、呼び出し前から deal_summary があるため、ほかの欄の登場を待つ
              expect(page.find("#deal_summary").value).to eq '朝食のサンドイッチ'
              expect(page.find('#deal_creditor_entries_attributes_0_reversed_amount').value).to be_empty
              expect(page).to have_css("#patterns div.clickable_text")
            end
          end

        end

        it "先に登録したデータがサジェッション表示される" do
          expect(page).to have_css("#patterns div.clickable_text")
          expect(page.find('#patterns')).to have_content('現金')
          expect(page.find('#patterns')).to have_content('クレジットカードＸ')
        end

      end

      describe "通常明細のパターン指定(id)" do
        let!(:pattern) { create(:deal_pattern,
                                :code => '',
                                :name => '',
                                :debtor_entries_attributes => [{:summary => '昼食', :account_id => Fixtures.identify(:taro_food), :amount => 800}],
                                :creditor_entries_attributes => [{:summary => '昼食', :account_id => Fixtures.identify(:taro_cache), :amount => -800}]
        ) }
        before do
          select_menu('家計簿')
          page.find("#recent_deal_patterns").click_link "*昼食" # パターンを指定
        end
        it "パターン登録した内容が入る" do
          sleep 1
          expect(page.find("#deal_debtor_entries_attributes_0_amount").value).to eq '800'
          expect(page.find("#deal_summary").value).to eq '昼食'
        end
      end

      describe "複数明細" do
        before do
          click_link "明細(複数)"
        end

        describe "タブを表示できる" do
          it "タブが表示される" do
            expect(page).to have_css('input#deal_creditor_entries_attributes_0_summary')
            expect(page).to have_css('input#deal_creditor_entries_attributes_1_summary')
            expect(page).to have_css('input#deal_creditor_entries_attributes_0_reversed_amount')
            expect(page).to have_css('input#deal_creditor_entries_attributes_1_reversed_amount')
            expect(page).to have_css('input#deal_creditor_entries_attributes_2_reversed_amount')
            expect(page).to have_css('input#deal_creditor_entries_attributes_3_reversed_amount')
            expect(page).to have_css('input#deal_creditor_entries_attributes_4_reversed_amount')
            expect(page).to have_css('select#deal_creditor_entries_attributes_0_account_id')
            expect(page).to have_css('select#deal_creditor_entries_attributes_1_account_id')
            expect(page).to have_css('select#deal_creditor_entries_attributes_2_account_id')
            expect(page).to have_css('select#deal_creditor_entries_attributes_3_account_id')
            expect(page).to have_css('select#deal_creditor_entries_attributes_4_account_id')
            expect(page).to have_css('input#deal_debtor_entries_attributes_0_amount')
            expect(page).to have_css('input#deal_debtor_entries_attributes_1_amount')
            expect(page).to have_css('input#deal_debtor_entries_attributes_2_amount')
            expect(page).to have_css('input#deal_debtor_entries_attributes_3_amount')
            expect(page).to have_css('input#deal_debtor_entries_attributes_4_amount')
            expect(page).to have_css('select#deal_debtor_entries_attributes_0_account_id')
            expect(page).to have_css('select#deal_debtor_entries_attributes_1_account_id')
            expect(page).to have_css('select#deal_debtor_entries_attributes_2_account_id')
            expect(page).to have_css('select#deal_debtor_entries_attributes_3_account_id')
            expect(page).to have_css('select#deal_debtor_entries_attributes_4_account_id')
          end
        end

        describe "記入欄を増やすことができる" do
          before do
            click_link '記入欄を増やす'
          end

          it "6つめの記入欄が表示される" do
            expect(page).to have_css('input#deal_creditor_entries_attributes_5_reversed_amount')
            expect(page).to have_css('select#deal_creditor_entries_attributes_5_account_id')
            expect(page).to have_css('input#deal_debtor_entries_attributes_5_amount')
            expect(page).to have_css('select#deal_debtor_entries_attributes_5_account_id')
          end
        end

        describe "1対2の明細の登録" do
          context "日付欄（月）にアルファベットがあるとき" do
            before do
              fill_in 'date_month', with: 'a' # アルファベット

              find('a.entry_summary').click # unifyモードにする
              fill_in 'deal_summary', :with => '買い物'
              fill_in 'deal_creditor_entries_attributes_0_reversed_amount', :with => '1000'
              select '現金', :from => 'deal_creditor_entries_attributes_0_account_id'
              fill_in 'deal_debtor_entries_attributes_0_amount', :with => '800'
              select '食費', :from => 'deal_debtor_entries_attributes_0_account_id'
              fill_in 'deal_debtor_entries_attributes_1_amount', :with => '200'
              select '雑費', :from => 'deal_debtor_entries_attributes_1_account_id'
              click_button '記入'
            end

            it "エラーが表示され、入れたままの文字が欄にある" do
              expect(page).to have_content('記入にエラーが発生しました。')
              expect(page).to have_content('日付を入力してください。')
              expect(find("input#date_month").value).to eq 'a'
            end
          end

          describe "金額" do
            before do
              find('a.entry_summary').click # unifyモードにする
              fill_in 'deal_summary', :with => '買い物'
              fill_in 'deal_creditor_entries_attributes_0_reversed_amount', :with => reversed_amount
              select '現金', :from => 'deal_creditor_entries_attributes_0_account_id'
              fill_in 'deal_debtor_entries_attributes_0_amount', :with => amount
              select '食費', :from => 'deal_debtor_entries_attributes_0_account_id'
              fill_in 'deal_debtor_entries_attributes_1_amount', :with => '200'
              select '雑費', :from => 'deal_debtor_entries_attributes_1_account_id'
              click_button '記入'
            end

            context "金額が正しいとき" do
              let(:reversed_amount) { '1000' }
              let(:amount) { '800' }
              it "登録でき、明細が一覧に表示される" do
                expect(flash_notice).to have_content('追加しました。')
                expect(page).to have_content '買い物'
                expect(page).to have_content '1,000'
                expect(page).to have_content '800'
                expect(page).to have_content '200'
                expect(current_hash).to eq "recent"
              end
            end

            context "貸方金額がアルファベットのとき" do
              let(:reversed_amount) { 'abc' }
              let(:amount) { '800' }
              it "エラーが表示される" do
                expect(page).to have_content 'エラーが発生しました。'
                expect(page).to have_content '金額は数値で入力してください。'
              end
            end

            context "借方金額がアルファベットのとき" do
              let(:reversed_amount) { '1000' }
              let(:amount) { 'abc' }
              it "エラーが表示される" do
                expect(page).to have_content 'エラーが発生しました。'
                expect(page).to have_content '金額は数値で入力してください。'
              end
            end

            context "金額の前後に半角スペースが含まれるとき" do
              let(:reversed_amount) { ' 1000 ' }
              let(:amount) { '    800' }
              it "登録でき、明細が一覧に表示される" do
                expect(flash_notice).to have_content('追加しました。')
                expect(page).to have_content '買い物'
                expect(page).to have_content '1,000'
                expect(page).to have_content '800'
                expect(page).to have_content '200'
                expect(current_hash).to eq "recent"
              end
            end
          end
        end
      end

      describe "残高" do
        before do
          click_link "残高"
        end

        describe "タブを表示できる" do
          it do
            expect(page).to have_css('select#deal_account_id')
            expect(page).to have_content('計算')
            expect(page).to have_content('残高')
            expect(page).to have_content('記入')

            expect(page).to_not have_css('input#deal_summary')
          end
        end

        describe "パレットをつかって登録できる" do
          before do
            select '現金', :from => 'deal_account_id'
            fill_in 'gosen', :with => '1'
            fill_in 'jyu', :with => '3'
            click_button '計算'
            click_button '記入'
          end

          it "一覧に表示される" do
            expect(flash_notice).to have_content("追加しました。")
            expect(page).to have_content("残高確認")
            expect(page).to have_content("5,030")
          end
        end

        context "日付欄（年）にアルファベットがあるとき" do
          before do
            fill_in 'date_year', with: 'a' # アルファベット

            select '現金', :from => 'deal_account_id'
            fill_in :deal_balance, with: '999'
            click_button '記入'
          end

          # 0000年で登録できる。ひとまず
          it "登録できる" do
            expect(flash_notice).to have_content("追加しました。")
            expect(page).to have_content("残高確認")
            expect(page).to have_content("999")
          end
        end

        describe "金額を入力した登録" do
          before do
            select '現金', :from => 'deal_account_id'
            fill_in :deal_balance, with: amount
            click_button '記入'
          end

          context "金額が正しいとき" do
            let(:amount) { '1003' }
            it "登録できる" do
              expect(flash_notice).to have_content("追加しました。")
              expect(page).to have_content("残高確認")
              expect(page).to have_content("1,003")
            end
          end

          context "金額がアルファベットのとき" do
            let(:amount) { 'abc' }
            it "エラーが表示される" do
              expect(page).to have_content("残高記入にエラーが発生しました。")
              expect(page).to have_content("残高は数値で入力してください。")
            end
          end

          context "金額の前後に半角スペースが含まれるとき" do
            let(:amount) { '   1003' }
            it "登録できる" do
              expect(flash_notice).to have_content("追加しました。")
              expect(page).to have_content("残高確認")
              expect(page).to have_content("1,003")
            end
          end

        end
      end
    end

    describe "変更" do

      context "単純明細の変更ボタンをクリックしたとき" do
        let!(:deal) { create(:general_deal, :date => Date.new(2012, 7, 10), :summary => "ラーメン") }
        before do
          visit "/deals/2012/7"
          click_link '変更'
        end
        it "URLにハッシュがつき、変更ウィンドウが表示される" do
          expect(page).to have_css("#edit_window")
          expect(find("#edit_window #date_year").value).to eq "2012"
          expect(find("#edit_window #date_month").value).to eq "7"
          expect(find("#edit_window #date_day").value).to eq "10"
          expect(find("#edit_window #deal_summary").value).to eq "ラーメン"
          expect(current_hash).to eq "d#{deal.id}"
        end
        it_behaves_like "複数記入に変更できる"
        it_behaves_like "変更を実行できる"
      end

      context "複数明細の変更ボタンをクリックしたとき" do
        let!(:deal) { create(:complex_deal, :date => Date.new(2012, 7, 7)) }
        before do
          visit "/deals/2012/7"
          click_link "変更"
        end
        it "URLにハッシュがつき、変更ウィンドウが表示される" do
          expect(page).to have_css("#edit_window")
          expect(find("#edit_window #date_year").value).to eq "2012"
          expect(find("#edit_window #date_month").value).to eq "7"
          expect(find("#edit_window #date_day").value).to eq "7"
          expect(current_hash).to eq "d#{deal.id}"
          expect(find("#deal_debtor_entries_attributes_0_amount").value).to be_present
          expect(find("#deal_creditor_entries_attributes_0_reversed_amount").value).to be_present
        end

        describe "変更を実行できる" do
          before do
            find("#date_day[value='7']")
            fill_in 'date_day', :with => '8'
            fill_in 'deal_debtor_entries_attributes_2_amount', :with => '103'
            select '食費', :from => 'deal_debtor_entries_attributes_2_account_id'
            fill_in 'deal_creditor_entries_attributes_2_reversed_amount', :with => '103'
            select 'クレジットカードＸ', :from => 'deal_creditor_entries_attributes_2_account_id'
            click_button '変更'
          end
          it "一覧に表示される" do
            expect(flash_notice).to have_content("更新しました。")
            expect(flash_notice).to have_content("2012/07/08")
            expect(page).to have_content('103')
            expect(page).to have_content('クレジットカードＸ')
          end
        end

        describe "カンマ入りの数字を入れて口座を変えても変更ができる" do
          # reversed_amount の代入時にparseされていない不具合がたまたまこのスペックで発見できた
          before do
            fill_in 'deal_creditor_entries_attributes_0_reversed_amount', :with => '1,200'
            fill_in 'deal_debtor_entries_attributes_0_amount', :with => '900'
            fill_in 'deal_debtor_entries_attributes_1_amount', :with => '300'
            select '銀行', :from => 'deal_creditor_entries_attributes_0_account_id'
            click_button '変更'
          end

          it "変更内容が一覧に表示される" do
            expect(flash_notice).to have_content "更新しました。"
            expect(page).to have_content '銀行'
            expect(page).to have_content '1,200'
            expect(page).to have_content '900'
            expect(page).to have_content '300'
          end
        end
      end

      context "残高明細の変更ボタンをクリックしたとき" do
        let!(:deal) { create(:balance_deal, :date => Date.new(2012, 7, 20), :balance => '2000') }
        before do
          visit "/deals/2012/7"
          click_link '変更'
        end
        it "URLにハッシュがつき、変更ウィンドウが表示される" do
          expect(page).to have_css("#edit_window")
          expect(find("#edit_window #date_year").value).to eq "2012"
          expect(find("#edit_window #date_month").value).to eq "7"
          expect(find("#edit_window #date_day").value).to eq "20"
          expect(current_hash).to eq "d#{deal.id}"
          expect(page).to have_content "一万円札"
          expect(find("#deal_balance").value).to eq "2000"
        end
        describe "実行できる" do
          before do
            fill_in 'deal_balance', :with => '2080'
            click_button '変更'
          end
          it "一覧に表示される" do
            expect(flash_notice).to have_content("更新しました。")
            expect(page).to have_content('2,080')
          end
        end
      end
    end

    describe "削除" do
      context "通常明細のとき" do
        let(:deal) { create(:general_deal, date: Date.new(2012, 7, 10)) }
        it_behaves_like "削除できる"
      end

      describe "複数明細" do
        let(:deal) { create(:complex_deal, :date => Date.new(2012, 7, 7))}
        it_behaves_like "削除できる"
      end

      describe "残高" do
        let(:deal) { create(:balance_deal, :date => Date.new(2012, 7, 20)) }
        it_behaves_like "削除できる"
      end
    end

  end

  describe "最近の記入" do
    before do
      create(:general_deal, summary: "昔の記入", date: Date.new(2012, 7, 10))
      select_menu('家計簿')
      click_link "最近の記入"
    end

    it "URLに #recent がつき、表示が変わる" do
      expect(current_hash).to eq "recent"
      expect(page).to have_content "昔の記入"
    end

    describe "月の一覧に戻せる" do
      before do
        click_link "総合(#{Time.zone.today.year}年 #{Time.zone.today.month}月)"
      end
      it "URLに #monthly がつき、表示が変わる" do
        expect(current_hash).to eq "monthly"
        expect(page).not_to have_content "昔の記入"
      end
    end

    # TODO: 登録、変更、削除

  end

end
