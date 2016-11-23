module TermsHelper
  def debtor_term(account)
    if bookkeeping_style?
      '借方'
    elsif account.kind_of?(Account::Asset)
      '入金'
    elsif account.kind_of?(Account::Income)
      '戻し'
    else
      '支出'
    end
  end

  def creditor_term(account)
    if bookkeeping_style?
      '貸方'
    elsif account.kind_of?(Account::Asset)
      '出金'
    elsif account.kind_of?(Account::Income)
      '収入'
    else
      '戻し'
    end
  end
end
