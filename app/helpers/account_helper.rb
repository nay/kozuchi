# 口座に関するヘルパー
module AccountHelper
  # 階層化した勘定選択欄を出力する。
  # * name - select_tag の名前
  # * accounts - Account::Baseの配列
  # * selected - 選択されているvalue
  # * options - select_tag のオプション
  def grouped_account_select(name, accounts, selected = nil, options = {})
    grouped_accounts = ApplicationHelper::AccountGroup.groups(
      accounts, true
    )
    select_tag name, option_groups_from_collection_for_select(grouped_accounts, :accounts, :name, :id, :name, selected), options
  end
end