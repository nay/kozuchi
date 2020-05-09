/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Month
class Month {
  constructor(year, month) {
    if ((month < 1) || (month > 12)) {
      month = 1;
    }
    this.year = year;
    this.month = month;
    this.months = (year * 12) + month;
  }

  refresh() {
    this.month = this.months % 12;
    this.year = (this.months - (this.months % 12)) / 12;
    if (this.month === 0) {
      this.month = 12;
      return this.year--;
    }
  }

  next() {
    this.months++;
    return this.refresh();
  }

  prev() {
    this.months--;
    return this.refresh();
  }

  set(month) {
    this.year = month.year;
    this.month = month.month;
    return this.months = month.months;
  }

  add(months) {
    this.months += months;
    return this.refresh();
  }

  subtract(months) {
    this.months -= months;
    return this.refresh();
  }

  minus(month) {
    return this.months - month.months;
  }

  equals(month) {
    return this.months === month.months;
  }
}

// Calendar
Calendar = class Calendar {
  constructor(callback) {
    this.selectedMonth = null;
    this.startMonth = null;
    this.callback = callback;
    this.leftMargin = 7;
  }

  selectMonth(year, month, call) {
    this.selectedMonth = new Month(year, month);

    this.startMonth = new Month(year, month);
    this.startMonth.subtract(this.leftMargin);

    const current = new Month(this.startMonth.year, this.startMonth.month);

    // year の変わり目を検査する
    // 1開始なら変わらない 2月以降なら変わる
    let colspan = 12;
    if (current.month >= 2) {
      colspan = 12 - (current.month - 1);
    }
    let yearClass = current.year % 2 ? 'odd_year' : 'even_year';

    let str = "<table>";
    str += "<tr>";
    str += "<td rowspan='2' id='prev_year' class='year_nav calendar_selector'" +
      "' data-year='"  + (this.selectedMonth.year - 1) +
      "' data-month='" + this.selectedMonth.month + "'>&lt;&lt;</td>";
    str += "<td class='year " + yearClass + "' colspan='" + colspan + "'>" + current.year + "</td>";
    if (colspan < 12) {
      const nextYear = current.year + 1;
      yearClass = nextYear % 2 ? 'odd_year' : 'even_year';
      const secondColspan = 12 - colspan;
      str += "<td class='year " + yearClass + "' colspan='";
      str += secondColspan;
      str += "'>" + nextYear + "</td>";
    }
    str += "<td rowspan='2' id='next_year' class='year_nav calendar_selector'" +
      "' data-year='"  + (this.selectedMonth.year + 1) +
      "' data-month='" + this.selectedMonth.month + "'>&gt;&gt;</td>";
    str += "</tr>";
    str += "<tr>";
    for (let i = 0; i <= 11; i++) {
      yearClass = current.year % 2  ? 'odd_year' : 'even_year';
      if (this.selectedMonth.equals(current)) {
        str += "<td class='selected_month month' id='month_" + current.year + "_" + current.month + "'><div class='" + yearClass + "'>";
      } else {
        str += "<td class='selectable_month month' id='month_" + current.year + "_" + current.month + "'>";
        str += "<div class='" + yearClass + "'>";
        str += "<a class='calendar_selector' data-year='" + current.year + "' data-month='" + current.month + "'>";
      }
      str += current.month + "月";
      if (!this.selectedMonth.equals(current)) {
        str += '</a>';
      }
      str += "</div>";
      str += '</td>';
      current.next();
    }
    str += "</tr>";
    str += "</table>";

    $("#calendar").get(0).innerHTML = str;

    $("#calendar_year").val(this.selectedMonth.year);
    $("#calendar_month").val(this.selectedMonth.month);

    // if call && @callback
      // @callback.call()
    if (call) {
      return $('#calendar').trigger('change', this.selectedMonth);
    }
  }
};

$(function() {
  if ($('#calendar').length > 0) {
    this.calendar = new Calendar();
    this.calendar.selectMonth($('#calendar').data('initial-year'), $('#calendar').data('initial-month'), false);
  }

  $(document).on('click', '#calendar .calendar_selector', function() {
    return document.calendar.selectMonth($(this).data('year'), $(this).data('month'), true);
  });
  return $(document).on('change', '#calendar.switcher', function(event, month) {
    const url = $(this).data('url-template').replace('_YEAR_', month.year).replace('_MONTH_', month.month);
    return location.href = url;
  });
});
