
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
    
    document.forms[0].year.value = selectedMonth.year;
    document.forms[0].month.value = selectedMonth.month;
    
    if (updatesBook) {
      document.forms[0].onsubmit();
    }
  }

  /**
      function : 残高編集モードにする
  **/
  function selectBalanceTab() {
    
  }    