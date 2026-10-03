import { Controller } from "@hotwired/stimulus"
import { visit } from "../turbo"

// 登録フォームの日付の欄
// 年・月を変えたら、その年月の一覧に Turbo Frame の中身を切り替える。入力した年月日はそのまま残す
// カレンダーなど、ほかの操作で Frame の中身が切り替わるときや、戻る・進むでページが描き直されるときは、
// 移動先の日付の欄の年月日に合わせる
export default class extends Controller {
  static targets = ["year", "month", "day"]
  static values = { frame: String, urlTemplate: String, year: Number, month: Number }

  // 年が4桁、月が1〜12で、表示中の年月と違うときだけ切り替える（入力の途中の値では切り替えない）
  navigate() {
    const year = this.yearTarget.value.trim()
    const month = this.monthTarget.value.trim()
    if (!/^\d{4}$/.test(year) || !/^\d{1,2}$/.test(month)) return
    const y = parseInt(year, 10)
    const m = parseInt(month, 10)
    if (m < 1 || m > 12) return
    if (y === this.yearValue && m === this.monthValue) return

    this.navigating = true
    visit(this.urlTemplateValue.replace("_YEAR_", y).replace("_MONTH_", m), this.frameValue)
  }

  // Turbo のページ単位の移動が始まるときに呼ばれる。戻る・進む（restore）かどうかを覚えておく
  visitStarted(event) {
    this.restoring = event.detail.action === "restore"
  }

  // Frame の中身を入れ替える直前（turbo:before-frame-render）と、ページを描き直す直前（turbo:before-render）に呼ばれる
  // この日付の欄は入れ替えずに残るので、移動先の画面の年月日を、入れ替えられる側の要素（#new_deal_datebox_source）から受け取る
  // ページの描き直しは、戻る・進むのときだけ対象にする（Frame の移動の後始末でも起きるが、そこでは合わせない）
  follow(event) {
    const { newFrame, newBody } = event.detail
    if (newFrame && event.target.id !== this.frameValue) return
    if (newBody && !this.restoring) return
    const source = (newFrame || newBody).querySelector(`#${this.element.id}_source`)
    if (!source) return

    this.yearValue = source.dataset.year
    this.monthValue = source.dataset.month
    if (this.navigating) {
      this.navigating = false
      return
    }
    this.yearTarget.value = source.dataset.year
    this.monthTarget.value = source.dataset.month
    this.dayTarget.value = source.dataset.day || ""
  }
}
