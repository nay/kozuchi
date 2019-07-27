xml.instruct!
xml.kozuchi(:timestamp => Time.zone.now.to_s(:db).gsub(/\s/, 'T'), :user => current_user.login, :version => KOZUCHI_VERSION) do
  xml.assets do
    current_user.assets.each{|a| a.to_xml(:builder => xml, :skip_instruct => true)}
  end
  xml.expenses do
    current_user.expenses.each{|a| a.to_xml(:builder => xml, :skip_instruct => true)}
  end
  xml.incomes do
    current_user.incomes.each{|a| a.to_xml(:builder => xml, :skip_instruct => true)}
#    current_user.assets.each{|a| xml.target! << a.to_xml(:skip_instruct => true)}
  end
  xml.deals do
    current_user.deals.includes(:readonly_entries).each{|d| d.to_xml(:builder => xml, :skip_instruct => true)}
  end
  xml.settlements do
    current_user.settlements.each{|s| s.to_xml(:builder => xml, :skip_instruct => true)}
  end
end