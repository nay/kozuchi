xml.instruct!
xml.kozuchi(:timestamp => Time.now.to_s(:db).gsub(/\s/, 'T'), :user => current_user.login) do
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
end