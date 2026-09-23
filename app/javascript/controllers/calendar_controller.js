import { Controller } from "@hotwired/stimulus"

// 月を選ぶカレンダー
// 選択中の月の7か月前から12か月分を表示し、月を選ぶと urlTemplate の _YEAR_, _MONTH_ を置き換えたURLへ移動する
export default class extends Controller {
  static values = { year: Number, month: Number, urlTemplate: String }

  // 左端に表示する、選択中の月より前の月数
  static leftMargin = 7

  connect() {
    this.element.innerHTML = this.html()
  }

  select(event) {
    const { year, month } = event.currentTarget.dataset
    location.href = this.urlTemplateValue.replace("_YEAR_", year).replace("_MONTH_", month)
  }

  html() {
    const selectedYear = this.yearValue
    const selectedMonth = (this.monthValue < 1 || this.monthValue > 12) ? 1 : this.monthValue
    // 年と月を、0年1月からの通算月数で扱う
    const selected = selectedYear * 12 + selectedMonth - 1
    const start = selected - this.constructor.leftMargin
    const yearOf = (months) => Math.floor(months / 12)
    const monthOf = (months) => months % 12 + 1
    const yearClass = (year) => year % 2 ? "odd_year" : "even_year"

    // 年の見出しは、表示する12か月が年をまたぐ場合は2つに分ける
    const firstYear = yearOf(start)
    const firstColspan = 12 - (monthOf(start) - 1)
    let str = "<table>"
    str += "<tr>"
    str += this.yearNavigator("prev_year", selectedYear - 1, selectedMonth, "&lt;&lt;")
    str += `<td class='year ${yearClass(firstYear)}' colspan='${firstColspan}'>${firstYear}</td>`
    if (firstColspan < 12) {
      str += `<td class='year ${yearClass(firstYear + 1)}' colspan='${12 - firstColspan}'>${firstYear + 1}</td>`
    }
    str += this.yearNavigator("next_year", selectedYear + 1, selectedMonth, "&gt;&gt;")
    str += "</tr>"

    str += "<tr>"
    for (let months = start; months < start + 12; months++) {
      const year = yearOf(months)
      const month = monthOf(months)
      const id = `month_${year}_${month}`
      if (months === selected) {
        str += `<td class='selected_month month' id='${id}'><div class='${yearClass(year)}'>${month}月</div></td>`
      } else {
        str += `<td class='selectable_month month' id='${id}'><div class='${yearClass(year)}'>` +
          `<a data-action='click->calendar#select' data-year='${year}' data-month='${month}'>${month}月</a>` +
          "</div></td>"
      }
    }
    str += "</tr>"
    str += "</table>"
    return str
  }

  yearNavigator(id, year, month, label) {
    return `<td rowspan='2' id='${id}' class='year_nav' data-action='click->calendar#select' data-year='${year}' data-month='${month}'>${label}</td>`
  }
}
