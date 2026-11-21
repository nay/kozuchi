require 'spec_helper'

describe Settings::AccountLinksController, type: :feature do
  fixtures :users, :accounts, :preferences, :friend_requests, :friend_permissions, :account_links, :account_link_requests

  include_context "太郎 logged in"

  describe "/settings/account_links" do
    context "シングルログインで切り替えていないとき" do
      before do
        visit settings_account_links_path
      end

      it "連携しているどの相手にも「解除」が出て、新しい連携の相手にフレンドを全員選べる" do
        expect(page).to have_link('解除', href: settings_account_link_path(account_id: Fixtures.identify(:taro_hanako)))
        expect(page).to have_link('解除', href: settings_account_link_path(account_id: Fixtures.identify(:taro_home)))
        expect(page).to have_select('linked_user_login', options: %w(hanako home))
      end
    end

    context "taroさんがhanakoさんに切り替えていて、homeさんはhanakoさんのフレンドだがtaroさんのフレンドではないとき" do
      before do
        current_user.friend_acceptances.find_by(target_id: Fixtures.identify(:home)).destroy
        current_user.single_logins.create!(login: 'hanako', password: 'hanako')
        visit home_path
        click_button 'taroさんでログイン中'
        click_link 'hanakoさんのアカウントへ移動'
        visit settings_account_links_path
      end

      it "taroさん本人との連携には「解除」が出て、homeさんとの連携には出ず、新しい連携の相手にはtaroさんだけを選べる" do
        expect(page).to have_link('解除', href: settings_account_link_path(account_id: Fixtures.identify(:hanako_taro)))
        expect(page).not_to have_link('解除', href: settings_account_link_path(account_id: Fixtures.identify(:hanako_home)))
        expect(page).to have_select('linked_user_login', options: %w(taro))
      end
    end
  end
end
