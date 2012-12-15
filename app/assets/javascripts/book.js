  /**
      function : 残高編集モードにする
  **/
  function selectBalanceTab() {
    
  }

 var money_counting_fields, money_counting_amounts;
 /**
  * function : 残高編集時に金額を計算する 
  */
 function countMoney() {
   var amount = 0;
   if (!money_counting_fields) money_counting_fields = ['man', 'gosen', 'nisen', 'sen', 'gohyaku', 'hyaku', 'gojyu', 'jyu', 'go', 'ichi'];
   if (!money_counting_amounts) money_counting_amounts = [10000, 5000, 2000, 1000, 500, 100, 50, 10, 5, 1];
   for(i = 0; i < money_counting_fields.length; i++) {
     if ($(money_counting_fields[i]).value != '') amount += (parseInt($(money_counting_fields[i]).value) * money_counting_amounts[i]);
   }
   $('deal_balance').value = amount;
 }

 function endOfMonth(year, month) {
   if (!year || year == '' || !month || month == '') return null

   year = parseInt(year)
   month = parseInt(month)

   nextYear = month == 12 ? year + 1 : year
   nextMonth = month == 12 ? 1 : month + 1
   
   return new Date(nextYear, nextMonth -1, 0).getDate()
 }