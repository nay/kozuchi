// Month
var Month = function(year, month) {
  if (month < 1 || month > 12) month = 1
  this.year = year;
  this.month = month;
  this.months = year * 12 + month;
}
Month.prototype = {

  refresh: function() {
    this.month = this.months % 12
    this.year = (this.months - (this.months % 12)) / 12
    if (this.month == 0) {
      this.month = 12
      this.year --
    }
  },

  next: function() {
    this.months++
    this.refresh()
  },

  prev: function() {
    this.months--;
    this.refresh()
  },

  set: function(month) {
    this.year = month.year
    this.month = month.month
    this.months = month.months
  },

  add: function(months) {
    this.months += months
    this.refresh()
  },

  subtract: function(months) {
    this.months -= months
    this.refresh()
  },

  minus: function(month) {
    return this.months - month.months;
  },

  equals: function(month) {
    return this.months == month.months;
  }
}

// Calendar
var Calendar = function(callback) {
  this.selectedMonth = null
  this.startMonth = null
  this.callback = callback
  this.leftMargin = 7
}

Calendar.prototype = {

  selectMonth: function(year, month, call) {
    this.selectedMonth = new Month(year, month)

    if (null == this.startMonth) {
      this.startMonth = new Month(year, month)
      this.startMonth.subtract(this.leftMargin)
    } else if (this.selectedMonth.minus(this.startMonth) < 0 || this.selectedMonth.minus(this.startMonth) >= 12) {
      this.startMonth.set(this.selectedMonth)
      this.startMonth.subtract(this.leftMargin)
    }

    var current = new Month(this.startMonth.year, this.startMonth.month)

    // year の変わり目を検査する
    // 1開始なら変わらない 2月以降なら変わる
    var colspan = 12
    if (current.month >= 2) {
      colspan = 12 - (current.month - 1)
    }

    var str = "<table>"
    str += "<tr>"
    str += "<td rowspan='2' style='width: 12px; cursor:pointer;' onClick='calendar.selectMonth("+ (this.selectedMonth.year - 1) +"," + this.selectedMonth.month+", true);'>&lt;&lt;</td>"
    str += "<td colspan='" + colspan + "'>" + current.year + "</td>"
    if (colspan < 12) {
      var nextYear = current.year + 1
      var secondColspan = 12 - colspan
      str += "<td colspan='" + secondColspan +"'>" + nextYear + "</td>"
    }
    str += "<td rowspan='2' style='width: 12px; cursor:pointer;' onClick='calendar.selectMonth("+ (this.selectedMonth.year + 1) +"," + this.selectedMonth.month+", true);'>&gt;&gt;</td>"
    str += "</tr>"
    str += "<tr>"
    for (var i = 0; i < 12; i++) {
      if (this.selectedMonth.equals(current)) {
        str += "<td class='selected_month' >"
      }
      else {
        str += "<td class='selectable_month'>"
        str += "<a style='display:block; text-decoration:none; text-align:right;' href='javascript:calendar.selectMonth(" + current.year + "," + current.month + ", true);'>"
      }
      str += current.month + "月"
      if (!this.selectedMonth.equals(current)) {
        str += '</a>'
      }
      str += '</td>'
      current.next()
    }
    str += "</tr>"
    str += "</table>"

    $("calendar").innerHTML = str

    $("calendar_year").value = this.selectedMonth.year
    $("calendar_month").value = this.selectedMonth.month

    if (call && this.callback) {
      this.callback.call()
    }
  }
}
