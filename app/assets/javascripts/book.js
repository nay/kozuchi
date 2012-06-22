
/**
  Class : Month
        : 月クラス
**/
var Month = Class.create();
Month.prototype = {
  initialize: function(_year, _month) {
    if (_month < 1 || _month > 12) {
      _month = 1;
    }
    this.year = _year;
    this.month = _month;
    this.months = _year * 12 + _month;
  },
        
  refresh: function() {
    this.month = this.months % 12;
    this.year = (this.months - (this.months % 12)) / 12;
    if (this.month == 0) {
      this.month = 12;
      this.year --;
    }
  },
        
  next: function() {
    this.months++;
    this.refresh();
  },
    
  prev: function() {
    this.months--;
    this.refresh();
  },

  set: function(_month) {
    this.year = _month.year;
    this.month = _month.month;
    this.months = _month.months;
  },

  add: function(_months) {
    this.months += _months;
    this.refresh();
  },

  minus: function(_month) {
    return this.months - _month.months;
  },

  equals: function(_month) {
    return this.months == _month.months;
  }
}


/**
  Class : Calendar
        : カレンダークラス
**/
var Calendar = Class.create();
Calendar.prototype = {
  initialize: function(callback) {
    this.selectedMonth = null;
    this.startMonth = null;
    this.callback = callback;
  },
  selectMonth: function(year, month, call) {
    this.selectedMonth = new Month(year, month);

    if (null == this.startMonth) {
      this.startMonth = new Month(year, month);
      this.startMonth.add(-3);
    }

    if (this.selectedMonth.minus(this.startMonth)<=0) {
      // 選択された月が開始月以前であるとき
      this.startMonth.set(this.selectedMonth);
      this.startMonth.add(-1);
    }
    // 指定された月が右端以降のとき
    else if (this.selectedMonth.minus(this.startMonth)>=5) {
      this.startMonth.set(this.selectedMonth);
      this.startMonth.add(-4);
    }


    var month = new Month(this.startMonth.year, this.startMonth.month);

    // year の変わり目を検査する
    // 1～7月開始なら変わらない 8月以降なら変わる
    var colspan = 6;
    if (month.month >= 8) {
      colspan = 6 - (month.month-7);
    }

    var str = "<table>";
    str += "<tr>";
    str += "<td colspan='" + colspan + "'>" + month.year + "</td>";
    if (colspan < 6) {
      var nextYear = month.year + 1;
      var secondColspan = 6 - colspan;
      str += "<td colspan='" + secondColspan +"'>" + nextYear + "</td>";
    }
    str += "</tr>"
    str += "<tr>"
//    var cur_year = month.year;
    for (var i = 0; i < 6; i++) {
      if (this.selectedMonth.equals(month)) {
        str += "<td class='selected_month' >";
      }
      else {
        str += "<td class='selectable_month' onClick='calendar.selectMonth("+month.year+","+month.month+", true); '>";
      }
      str += month.month + "月</td>";
      month.next();
    }
    str += "</tr>"
    str += "</table>"

    $("calendar").innerHTML = str;

    $("calendar_year").value = this.selectedMonth.year;
    $("calendar_month").value = this.selectedMonth.month;

    if (call && this.callback) {
      this.callback.call();
//      document.forms.month_form.submit();
    }
  }
}


  var selectedMonth = null;
  var startMonth = null;

  /** 月の選択 **/
  function select_month(year, month, updatesBook) {
    selectedMonth = new Month(year, month);
    
    if (null == startMonth) {
      startMonth = new Month(year, month);
      startMonth.add(-3);
    }
    
    if (selectedMonth.minus(startMonth)<=0) {
      // 選択された月が開始月以前であるとき
      startMonth.set(selectedMonth);
      startMonth.add(-1);
    }
    // 指定された月が右端以降のとき
    else if (selectedMonth.minus(startMonth)>=5) {
      startMonth.set(selectedMonth);
      startMonth.add(-4);
    }
    

    var month = new Month(startMonth.year, startMonth.month);
    
    // year の変わり目を検査する
    // 1～7月開始なら変わらない 8月以降なら変わる
    var colspan = 6;
    if (month.month >= 8) {
      colspan = 6 - (month.month-7);
    }
            
    var str = "<table>";
    str += "<tr>";
    str += "<td colspan='" + colspan + "'>" + month.year + "</td>";
    if (colspan < 6) {
      var nextYear = month.year + 1;
      var secondColspan = 6 - colspan;
      str += "<td colspan='" + secondColspan +"'>" + nextYear + "</td>";
    }
    str += "</tr>"
    str += "<tr>"
    var cur_year = month.year;
    for (var i = 0; i < 6; i++) {
      if (selectedMonth.equals(month)) {
        str += "<td class='selected_month' >";
      }
      else {
        str += "<td class='selectable_month' onClick='select_month("+month.year+","+month.month+", true); '>";
      }
      str += month.month + "月</td>";
      month.next();
    }
    str += "</tr>"
    str += "</table>"

    $("calendar").innerHTML = str;
    
    $("calendar_year").value = selectedMonth.year;
    $("calendar_month").value = selectedMonth.month;
    
    if (updatesBook) {
      document.forms.month_form.submit();
    }
  }

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