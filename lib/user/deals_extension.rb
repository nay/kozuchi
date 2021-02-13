# Userのdeals関連(DealはBaseDealではなくDeal）の拡張を記述する。
# User本体とコードを分けて整理するためモジュールで記述。
module User::DealsExtension
  # keywordsをsummaryに含む明細をすべて検索する。 keywordsは配列で受け取り、and検索する。
  def including(keywords)
    raise ArgumentError.new("No keywords") if keywords.blank?
    select("deals.*"
    ).joins("inner join account_entries on account_entries.deal_id = deals.id"
    ).where(keywords.map{"account_entries.summary like ?"}.join(' and '), *keywords.map{|k| "%#{k}%"})
  end
  
  # summary の前方一致で検索する
  # TODO: search_by_summary から置き換えるが、NamedScopeが欲しい。
  def begin_with(summary_key, limit = nil)
    raise ArgumentError.new("No summary_key") if summary_key.blank?
    # まず summary と 日付(TODO: created_at におきかえたい)のセットを返す
    results = select("summary, max(date) as date"
    ).where("summary like ?", "#{summary_key}%"
    ).group("summary"
    ).limit(limit)
    result.empty? ? [] : where(results.map{|r| "(summary = ? and date = ?)"}.join(" or "), *results.map{|r| [r.summary, r.date]}.flatten)
  end

  # 指定された期間の取引データを取得する。旧 get_for_accounts
  def in_range(start_date, end_date, accounts)
    raise ArgumentError.new("No start_date") unless start_date
    raise ArgumentError.new("No end_date") unless start_date
    raise ArgumentError.new("No accounts") if accounts.blank?
    select("distinct dl.*"
    ).where("et.account_id in (?) and dl.date >= ? and dl.date < ?",
                                  accounts.map{|a| a.id},
                                  start_date,
                                  end_date + 1
    ).joins("as dl inner join account_entries as et on dl.id = et.deal_id"
    ).order("dl.date, dl.daily_seq")
  end

end