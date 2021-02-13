require 'spec_helper'

describe UsersController, type: :feature do
  fixtures :users, :preferences

  describe "GET /signup" do
    context "when not logged in" do
      before do
        visit '/signup'
      end
      it_behaves_like 'users/new'
    end
  end

  describe "ユーザー登録できる" do
    context "メール送信をスキップする設定のとき" do
      before do
        SKIP_MAIL = true # 警告が出るがしかたない。TODO: 変更可能な形態にする
        visit "/"
        click_link "アカウント登録して使い始める（無料）"
        fill_in "ログインID", with: "featuretest"
        fill_in "Email", with: "featuretest@kozuchi.net"
        fill_in "パスワード", with: "testtest"
        fill_in "パスワード（確認）", with: "testtest"
        click_button "ユーザー登録"
      end

      it do
        expect(flash_notice).to have_content "登録が完了しました。"
        expect(page.current_path).to eq "/home"
      end
    end

    context "メール送信ありの設定のとき" do
      before do
        SKIP_MAIL = false # 警告が出るがしかたない。TODO: 変更可能な形態にする
        visit "/"
        click_link "アカウント登録して使い始める（無料）"
        fill_in "ログインID", with: "featuretest"
        fill_in "Email", with: "featuretest@kozuchi.net"
        fill_in "パスワード", with: "testtest"
        fill_in "パスワード（確認）", with: "testtest"
        click_button "ユーザー登録"
      end

      it do
        expect(page).to have_content "ご登録ありがとうございます。確認メールが送信されますので、記載されているURLからアカウントを有効にしてください。"
      end
    end
  end

  describe "パスワードを忘れたとき" do
    context "メール送信をスキップする設定のとき" do
      before do
        SKIP_MAIL = true # 警告が出るがしかたない。TODO: 変更可能な形態にする
        visit "/"
        click_link "パスワードを忘れたとき"
      end
      it { expect(page).to have_content "現在、システムからメールを送信しない設定となっているため、Webからパスワード再設定をしていただくことができません。" }
    end

    context "メール送信ありの設定のとき" do
      before do
        SKIP_MAIL = false # 警告が出るがしかたない。TODO: 変更可能な形態にする
        visit "/"
        click_link "パスワードを忘れたとき"
      end
      it { expect(page).to have_css("input#email") }

      describe "パスワード変更の申し込み実行" do
        before do
          fill_in :email, with: email
          click_button "パスワード変更を希望する"
        end
        context "登録されているメールアドレスのとき" do
          let(:email) { "taro@kozuchi.net" }
          it { expect(page).to have_content "パスワード変更のための情報を #{email} へ送信しました。"}

          describe "パスワード変更画面へのアクセス" do
            let(:password_token) { User.find_by!(email: email).password_token }
            before do
              visit "/password/#{password_token}"
            end

            # TODO: 期限切れのケースも追加したい
            it "パスワード変更画面が表示される" do
              expect(page).to have_css "input#password"
              expect(page).to have_css "input#password_confirmation"
              # TODO: ちゃんと定義したい
            end

            describe "パスワード変更の実行" do
              before do
                fill_in "パスワード", with: "newpassword"
                fill_in "パスワード（確認）", with: "newpassword"
                click_button "パスワード変更"
              end

              it do
                expect(page.current_path).to eq("/home")
                expect(flash_notice).to have_content "パスワードを変更しました。"
              end

              describe "パスワード変更後のログイン" do
                before do
                  click_link "ログアウト"
                  fill_in "ログインID", with: "taro"
                  fill_in "パスワード", with: "newpassword"
                  click_button "ログイン"
                end

                it { expect(page).to have_content "taroさん、ようこそWeb家計簿「小槌」へ！"}
              end
            end
          end
        end
        context "登録されていないメールアドレスのとき" do
          let(:email) { "unknown@kozuchi.net" }
          it { expect(page).to have_content "該当するユーザーは登録されていません。" }
        end
      end
    end
  end
end
