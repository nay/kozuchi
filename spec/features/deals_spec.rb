require 'spec_helper'

describe DealsController, type: :feature do
  fixtures :users, :accounts, :preferences

  # 一覧
  describe "/deals/2012/7" do
    include_context "太郎 logged in"
    context "with no deals" do
      before do
        visit "/deals/2012/7"
      end
      it "明細表示領域がある" do
        expect(page).to have_css('div#monthly_contents')
      end
      it "日ナビゲーターがある" do
        expect(page).to have_css('#day_navigator')
      end
    end

    context "with one balance deal" do
      before do
        create(:balance_deal, :date => Date.new(2012, 7, 20))
        visit "/deals/2012/7"
      end
      it do
        expect(page).to have_content("2012/07/20")
      end
    end
  end

  # 日で絞った一覧
  describe "日で絞った一覧" do
    include_context "太郎 logged in"
    context "2012年7月19日と20日に記入があるとき" do
      before do
        create(:general_deal, summary: "19日のランチ", date: Date.new(2012, 7, 19))
        create(:general_deal, summary: "20日のランチ", date: Date.new(2012, 7, 20))
      end

      context "総合の20日の一覧を開いたとき" do
        before do
          visit "/deals/2012/7/20"
        end

        it "20日の記入だけが、20日で絞った一覧として表示される" do
          expect(page).to have_content("総合(2012年7月20日)")
          expect(page).to have_content("20日のランチ")
          expect(page).not_to have_content("19日のランチ")
        end

        it "日ナビゲーターでは、19日にも20日にも記入の印が付く" do
          [19, 20].each do |day|
            expect(page).to have_css("#day_navigator tr", text: /#{Regexp.escape(I18n.l(Date.new(2012, 7, day), format: :day).strip)}\s*\*/)
          end
        end
      end

      context "現金の20日の一覧を開いたとき" do
        before do
          visit "/accounts/#{Fixtures.identify(:taro_cache)}/deals/2012/7/20"
        end

        it "20日の記入だけが表示され、期首残高は19日までの残高になる" do
          expect(page).to have_content("現金(2012年7月20日)")
          expect(page).to have_content("20日のランチ")
          expect(page).not_to have_content("19日のランチ")
          expect(page).to have_css("tr", text: /期首残高\s*-800/)
        end
      end
    end

    context "9月31日の一覧を開いたとき" do
      before do
        visit "/deals/2012/9/31"
      end

      it "9月30日の一覧に移る" do
        expect(page).to have_current_path("/deals/2012/9/30")
        expect(page).to have_content("総合(2012年9月30日)")
      end
    end
  end

  # 年月を指定しない移動
  describe "最後に表示した一覧への移動" do
    include_context "太郎 logged in"
    context "花子さんへのシングルログインを設定し、2012年7月の一覧を表示してから、2012年6月の一覧を表示したとき" do
      before do
        SingleLogin.create!(user: current_user, login: 'hanako', password: 'hanako')
        visit "/deals/2012/7"
        visit "/deals/2012/6"
      end

      context "年月を指定せずに一覧を開いたとき" do
        before do
          visit "/deals"
        end

        it "2012年6月の一覧が表示される" do
          expect(page).to have_current_path("/deals/2012/6")
        end
      end

      context "シングルログインで花子さんのアカウントへ移動したとき" do
        before do
          click_link 'hanakoさんのアカウントへ移動'
        end

        it "花子さんの2012年6月の一覧が表示される" do
          expect(page).to have_content("hanakoさんに切り替え中")
          expect(page).to have_current_path("/deals/2012/6")
        end
      end
    end

    context "花子さんへのシングルログインを設定し、2012年6月20日で絞った一覧を表示したとき" do
      before do
        SingleLogin.create!(user: current_user, login: 'hanako', password: 'hanako')
        visit "/deals/2012/6/20"
      end

      context "年月を指定せずに一覧を開いたとき" do
        before do
          visit "/deals"
        end

        it "2012年6月20日で絞った一覧が表示される" do
          expect(page).to have_current_path("/deals/2012/6/20")
        end
      end

      context "シングルログインで花子さんのアカウントへ移動したとき" do
        before do
          click_link 'hanakoさんのアカウントへ移動'
        end

        it "花子さんの2012年6月20日で絞った一覧が表示される" do
          expect(page).to have_content("hanakoさんに切り替え中")
          expect(page).to have_current_path("/deals/2012/6/20")
        end
      end

      context "さらに2012年6月の一覧を表示してから、年月を指定せずに一覧を開いたとき" do
        before do
          visit "/deals/2012/6"
          visit "/deals"
        end

        it "2012年6月の一覧が表示される" do
          expect(page).to have_current_path("/deals/2012/6")
        end
      end
    end
  end

  # 検索
  describe "/deals/search" do
    include_context "太郎 logged in"
    before do
      visit "/deals/2012/7"
    end

    context "when no deal with the keyword exists" do
      before do
        fill_in 'keyword', :with => 'test'
        click_button('検索')
      end
      it do
        expect(page).to have_content("「test」を含む明細は登録されていません。")
      end
    end

    context "when one deal with the keyword exists" do
      before do
        @deal = create(:general_deal, :date => Date.new(2012, 7, 10))
        fill_in 'keyword', :with => 'ランチ'
        click_button('検索')
      end
      it do
        expect(page).to have_content("「ランチ」を含む明細は1件あります。")
      end
    end
  end

end