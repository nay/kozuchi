# 異動明細クラス。
class Deal < BaseDeal
  attr_accessor :minus_account_id, :plus_account_id, :amount
  has_many   :children,
             :class_name => 'SubordinateDeal',
             :foreign_key => 'parent_deal_id',
             :dependent => true

  # 自分の取引のなかに指定された口座IDが含まれるか
  def has_account(account_id)
    for entry in account_entries
      return true if entry.account.id == account_id
    end
    return false
  end
  
  # 子取引のなかに指定された口座IDが含まれればそれをかえす
  def child_for(account_id)
    for child in children
      return child if child.has_account(account_id)
    end
    return false
  end

  def before_save
    pre_before_save
  end

  def before_create
    create_relations
    create_friend_deals
  end
  
  def before_update
    clear_friend_deals(get_friend_deal_ids_to_be_cleared)
    clear_relations
    create_relations
    create_friend_deals
  end

  # Prepare sugar methods
  def after_find
    set_old_date
    raise "Invalid Deal Object with #{account_entries.size} entries." unless account_entries.size == 2
    
    @minus_account_id = account_entries[0].account_id
    @plus_account_id = account_entries[1].account_id
    @amount = account_entries[1].amount
  end
  
  def before_destroy
    # フレンドリンクまたは本体までを消す
    clear_friend_deals
  end
  
  private

  def clear_relations
    account_entries.clear
    children.clear
  end
  
  def create_relations
    # 小さいほうが前になるようにする。これにより、minus, plus, amount は値が逆でも差がなくなる
    if @amount.to_i >= 0
      account_entries.create(:user_id => user_id, :account_id => @minus_account_id, :amount => @amount.to_i*(-1))
    end
    account_entries.create(:user_id => user_id, :account_id => @plus_account_id, :amount => @amount.to_i)
    if @amount.to_i < 0
      account_entries.create(:user_id => user_id, :account_id => @minus_account_id, :amount => @amount.to_i*(-1))
    end

    for i in 0..1
      account_rule = account_entries[i].account.account_rule
      # 精算ルールに従って従属行を用意する
      if account_rule
        # どこからからルール適用口座への異動額
        new_amount = account_entries[0].account_id == account_rule.account_id ? account_entries[0].amount : account_entries[1].amount
        # 適用口座がクレジットカードなら、出金元となっているときだけルールを適用する。債権なら入金先となっているときだけ適用する。
        if (Account::ASSET_CREDIT_CARD == account_rule.account.asset_type && new_amount < 0) ||(Account::ASSET_CREDIT == account_rule.account.asset_type && new_amount > 0)
          children.create(
            :minus_account_id => account_rule.account_id,
            :plus_account_id => account_rule.associated_account_id,
            :amount => new_amount,
            :user_id => self.user_id,
            :date => account_rule.payment_date(self.date),
#            :date => self.date  >> 1,
            :summary => "",
            :confirmed => false)
        end
      end
    end
  end
  
  def create_friend_deals
    # フレンド連動に従ってフレンド行を用意する
    for i in 0..1
      next if !self.confirmed # お手玉を防ぐ

      friend_user = account_entries[i].account.friend_user
      p "create_friend_deals : friend_user = #{friend_user}, confirmed = #{self.confirmed}"
      next if !friend_user #　関係ない口座

      # すでにある場合（更新時）は登録しない      
      find_friend_deal = false
      for friend_deal in self.friend_deals(true)
        if friend_deal.friend_deal.user.id == friend_user.id
          find_friend_deal = true
          break
        end
      end
      p "found #{friend_user.login_id}'s friend_deal. Supposed this update didn't change #{friend_user.login_id}'s amount." if find_friend_deal
      next if find_friend_deal

      my_account = Account.find_credit(friend_user.id, User.find(self.user_id).login_id)
      p "my_account = #{my_account}"
      next if !my_account # 先方に自分の口座がない
      
      other_account = Account.find_default_asset(friend_user.id)
      next if !other_account || other_account.id == my_account.id # 先方に入れるべきデフォルト口座がない
      
      friend_real_deal = Deal.create(
              :minus_account_id => my_account.id,
              :plus_account_id => other_account.id,
              :amount => account_entries[i].amount, # my account の friend 口座にプラスがはいったなら、マイナス額
              :user_id => friend_user.id,
              :date => self.date,
              :summary => self.summary,
              :confirmed => false
      )
      # 相手側リンクは下記が実行されたタイミング（たぶんこのdealがクリエイトされたとき）で自動的に作られる
      self.friend_deals.create(
              :user_id => self.user_id,
              :friend_deal_id => friend_real_deal.id
      )
    end
  end
  
  def clear_friend_deals(ids_to_be_cleared = nil)
    for friend_deal in friend_deals
      next if ids_to_be_cleared && !ids_to_be_cleared.find{|e| e==friend_deal.id}
      friend_real_deal = friend_deal.friend_deal
      # まずリンクを切る
      friend_deal.destroy # 相手方リンクも連動して削除される
      if !friend_real_deal.confirmed
        # 未確認なら、本体も削除する
        friend_real_deal.destroy
      end
    end
  end
  
  def get_friend_deal_ids_to_be_cleared
    current = Deal.find(self.id) # 変更前オブジェクト
    friend_deal_ids_to_be_cleared = []
    for account_entry in current.account_entries
      for friend_deal in current.friend_deals
        if account_entry.account.friend_user && account_entry.account.friend_user.id == friend_deal.friend_deal.user.id
          new_amount = minus_account_id == account_entry.account_id ? self.amount * -1 : self.amount
          if account_entry.amount != new_amount
            friend_deal_ids_to_be_cleared << friend_deal.id
            break
          end
        end
      end
    end
    return friend_deal_ids_to_be_cleared
  end
  
  
  
  
end
