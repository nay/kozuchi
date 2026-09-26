import { Controller } from "@hotwired/stimulus"

// 日を押すと、月の一覧のタブに切り替え、記入日の日の欄に押した日を入れる
// タブの切り替えは deals.js の jQuery のハンドラが行っているので、jQuery でクリックを発生させる
export default class extends Controller {
  select(event) {
    $(".body_tab_link[data=monthly]").click()
    $("input#date_day").val(event.currentTarget.dataset.day)
  }
}
